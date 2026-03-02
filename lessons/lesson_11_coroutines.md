# Lesson 11: Coroutines

The Lua reference manual describes coroutines as follows: *"Lua supports
coroutines, also called collaborative multithreading. A coroutine in Lua
represents an independent thread of execution. Unlike threads in multithread
systems, however, a coroutine only suspends its execution by explicitly
calling a yield function."*

Coroutines are not preemptive — only one runs at a time, and they must
explicitly yield control. This makes them easy to reason about, and ideal
for iterators, generators, event-driven systems, and cooperative scheduling.

---

## 1. The Four Coroutine States

A coroutine can be in one of four states:

| State | Meaning |
|-------|---------|
| `"suspended"` | created but not yet started, or yielded |
| `"running"` | currently executing |
| `"normal"` | resumed another coroutine (not running, not suspended) |
| `"dead"` | returned or errored; cannot be resumed again |

Example:
```lua
local co = coroutine.create(function() end)
coroutine.status(co)   -- not yet started
```
```expected
suspended
```

---

Example:
```lua
local co = coroutine.create(function() return "done" end)
coroutine.resume(co)
coroutine.status(co)   -- finished
```
```expected
dead
```

---

## 2. coroutine.create and coroutine.resume

`coroutine.create(fn)` creates a coroutine but does not start it.
`coroutine.resume(co, ...)` starts or continues it, passing arguments in.

Returns: `true, results...` on success, or `false, error_message` on error.

Example:
```lua
local co = coroutine.create(function(a, b)
  return a + b
end)
local ok, result = coroutine.resume(co, 10, 20)
tostring(ok) .. "/" .. tostring(result)
```
```expected
true/30
```

---

## 3. coroutine.yield

`coroutine.yield(...)` suspends the running coroutine.
- Values passed to `yield` are returned by `resume` to the caller.
- Values passed to the *next* `resume` become the return values of `yield`.

Example:
```lua
local co = coroutine.create(function()
  local x = coroutine.yield(1)   -- suspend, send 1 out, wait for next resume
  local y = coroutine.yield(2)   -- suspend, send 2 out, wait for next resume
  return x + y                   -- finish with sum of what was sent in
end)

local _, a = coroutine.resume(co)          -- starts, gets 1 from yield
local _, b = coroutine.resume(co, 10)      -- sends 10 in, gets 2 from yield
local _, c = coroutine.resume(co, 20)      -- sends 20 in, gets x+y = 30
tostring(a) .. "," .. tostring(b) .. "," .. tostring(c)
```
```expected
1,2,30
```

---

## 4. coroutine.wrap

`coroutine.wrap(fn)` is a convenience wrapper that:
- Creates a coroutine for `fn`
- Returns a *function* that resumes it
- The function raises an error (instead of returning false) on failure

Example:
```lua
local gen = coroutine.wrap(function()
  for i = 1, 5 do
    coroutine.yield(i)
  end
end)

local results = {}
for i = 1, 5 do
  table.insert(results, gen())
end
table.concat(results, ",")
```
```expected
1,2,3,4,5
```

---

## 5. Using Coroutines as Generators

Coroutines are perfect for lazy sequences — values are produced only when
needed:

Example:
```lua
local function range(from, to, step)
  step = step or 1
  return coroutine.wrap(function()
    local i = from
    while i <= to do
      coroutine.yield(i)
      i = i + step
    end
  end)
end

local sum = 0
for v in range(1, 10) do
  sum = sum + v
end
sum
```
```expected
55
```

---

Example:
```lua
-- Fibonacci generator (infinite)
local function fibonacci()
  return coroutine.wrap(function()
    local a, b = 0, 1
    while true do
      coroutine.yield(a)
      a, b = b, a + b
    end
  end)
end

local results = {}
local gen = fibonacci()
for i = 1, 8 do
  table.insert(results, gen())
end
table.concat(results, ",")
```
```expected
0,1,1,2,3,5,8,13
```

---

## 6. Tree Traversal with Coroutines

Coroutines make recursive iterators trivial to write:

Example:
```lua
local function walk(tree)
  return coroutine.wrap(function()
    local function recurse(node)
      if type(node) == "table" then
        for _, child in ipairs(node) do
          recurse(child)
        end
      else
        coroutine.yield(node)
      end
    end
    recurse(tree)
  end)
end

local result = {}
for v in walk({1, {2, {3, 4}}, {5, 6}}) do
  table.insert(result, v)
end
table.concat(result, ",")
```
```expected
1,2,3,4,5,6
```

---

## 7. Producer-Consumer Pattern

Coroutines enable clean separation of producers and consumers:

Example:
```lua
local function producer(data)
  return coroutine.create(function()
    for _, v in ipairs(data) do
      coroutine.yield(v)
    end
  end)
end

local function consume(prod, transform)
  local results = {}
  while true do
    local ok, val = coroutine.resume(prod)
    if not ok or val == nil then break end
    table.insert(results, transform(val))
  end
  return results
end

local prod = producer({1, 2, 3, 4, 5})
local output = consume(prod, function(v) return v * v end)
table.concat(output, ",")
```
```expected
1,4,9,16,25
```

---

## 8. Coroutine Pipeline

Chain multiple coroutines like Unix pipes:

Example:
```lua
local function source(t)
  return coroutine.wrap(function()
    for _, v in ipairs(t) do coroutine.yield(v) end
  end)
end

local function filter_co(iter, pred)
  return coroutine.wrap(function()
    for v in iter do
      if pred(v) then coroutine.yield(v) end
    end
  end)
end

local function map_co(iter, fn)
  return coroutine.wrap(function()
    for v in iter do coroutine.yield(fn(v)) end
  end)
end

-- Pipeline: source → filter evens → double
local pipeline = map_co(
  filter_co(source({1,2,3,4,5,6}), function(v) return v%2==0 end),
  function(v) return v*2 end
)

local result = {}
for v in pipeline do table.insert(result, v) end
table.concat(result, ",")
```
```expected
4,8,12
```

---

## 9. Error Handling in Coroutines

If a coroutine body raises an error, `resume` returns `false, error`:

Example:
```lua
local co = coroutine.create(function()
  error("oops!")
end)
local ok, err = coroutine.resume(co)
tostring(ok)
```
```expected
false
```

---

Example:
```lua
-- After an error, the coroutine is dead
local co = coroutine.create(function()
  error("fail")
end)
coroutine.resume(co)
coroutine.status(co)
```
```expected
dead
```

---

## 10. coroutine.running

`coroutine.running()` returns the running coroutine and a boolean
indicating whether it's the main thread:

Example:
```lua
local co = coroutine.create(function()
  local me, is_main = coroutine.running()
  coroutine.yield(type(me), is_main)
end)
local _, t, is_main = coroutine.resume(co)
tostring(t) .. "/" .. tostring(is_main)
```
```expected
thread/false
```

---

---

# Exercises

---

### Exercise 1 — Basic yield

Create a coroutine that yields "one", "two", "three" in sequence.
Resume 3 times and collect results. Return them joined with ", ".
> Tip: `local _, v = coroutine.resume(co)` each time.

```lua
-- your code here
```
```expected
one, two, three
```

---

### Exercise 2 — Status lifecycle

Create a coroutine that yields once then returns.
Track its status: after create, after first resume (mid-yield), after second resume.
Return the three statuses joined by "/".
> Tip: statuses are "suspended" / "suspended" / "dead".

```lua
-- your code here
```
```expected
suspended/suspended/dead
```

---

### Exercise 3 — Two-way communication

Create a coroutine that:
- Yields its argument doubled
- Then returns the square of what was passed to the second resume

Call with first resume arg=5 (expect 10 yielded back), second resume arg=3 (expect 9).
Return the final result.
> Tip: `local x = coroutine.yield(arg * 2)` inside the coroutine.

```lua
-- your code here
```
```expected
9
```

---

### Exercise 4 — wrap generator

Use `coroutine.wrap` to create a powers-of-2 generator.
Sum the first 8 values: 1+2+4+8+16+32+64+128 = 255.
> Tip: start at 1, yield, then multiply by 2 each step.

```lua
-- your code here
```
```expected
255
```

---

### Exercise 5 — range with step

Write a `range(from, to, step)` generator using coroutine.wrap.
Sum range(0, 20, 3) — that's 0+3+6+9+12+15+18 = 63.
> Tip: yield values while i <= to; increment by step.

```lua
-- your code here
```
```expected
63
```

---

### Exercise 6 — Error handling

Create a coroutine that will error. Verify that resume returns `false`.
Return just that first return value (should be false).
> Tip: resume returns false as first value if the coroutine errors.

```lua
-- your code here
```
```expected
false
```

---

### Exercise 7 — Infinite sequence + take

Write a coroutine-based infinite sequence of natural numbers starting at 1.
Write a `take(gen, n)` that collects the first n values into a table.
Take the first 5 and return their sum.
> Tip: the generator loops `while true do yield(i); i=i+1 end`.

```lua
-- your code here
```
```expected
15
```

---

### Exercise 8 — Challenge: pipeline

Build a three-stage coroutine pipeline:
1. Source: yields numbers 1..10
2. Filter: keeps only numbers divisible by 2
3. Map: multiplies each by 3

Collect results and return table.concat with ",".
> Tip: wrap each stage in coroutine.wrap, pass the previous stage's iterator in.

```lua
-- your code here
```
```expected
6,12,18,24,30
```
