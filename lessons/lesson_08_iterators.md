# Lesson 08: Iterators and the Generic For

The Lua reference manual says the generic for loop has the form:
`for var-list in explist do block end`

It calls an iterator function on each step. Understanding how this works
lets you write clean, expressive code and your own iterators.

---

## How the generic for works internally

The generic for evaluates `explist` once to get three values:
1. The **iterator function** (called each step)
2. The **state** (passed to the iterator each step)
3. The **control variable** (initial value, updated each step)

On each step it calls `iterator(state, control_var)` and uses the
first returned value as the new control variable. The loop stops when
this is `nil`:

Example:
```lua
-- Manually doing what "for i,v in ipairs(t)" does internally:
local t = {"a", "b", "c"}
local iter, state, init = ipairs(t)
local i, v = iter(state, init)
i .. "=" .. v
```
```expected
1=a
```

---

## ipairs — sequential iteration

Iterates from 1 upward, stopping at the first `nil`:

Example:
```lua
local result = {}
for i, v in ipairs({"x", "y", "z"}) do
  table.insert(result, i .. v)
end
table.concat(result, ",")
```
```expected
1x,2y,3z
```

---

## pairs — all-key iteration

`pairs(t)` uses `next` internally. Order is not guaranteed for
non-sequential keys. Integer keys in sequence tend to come first
but this is implementation-dependent:

Example:
```lua
local t = {a=1, b=2, c=3}
local sum = 0
for k, v in pairs(t) do sum = sum + v end
sum
```
```expected
6
```

---

## next() — the iterator behind pairs

`next(t, key)` returns the next key-value pair after `key`.
Passing `nil` returns the first pair. Returns `nil` when exhausted:

Example:
```lua
local t = { x = 10 }
local k, v = next(t, nil)
k .. "=" .. v
```
```expected
x=10
```

---

## Stateless iterators

A stateless iterator only uses its arguments — no upvalues needed.
`ipairs` is stateless: the state is the table, the control var is the index:

Example:
```lua
local function values(t, i)
  i = i + 1
  local v = t[i]
  if v ~= nil then return i, v end
end

local out = {}
for i, v in values, {"p", "q", "r"}, 0 do
  table.insert(out, v)
end
table.concat(out, "")
```
```expected
pqr
```

---

## Stateful iterators (closures)

Closures carry their own state — no need to pass it via the generic for:

Example:
```lua
local function range(n)
  local i = 0
  return function()
    i = i + 1
    if i <= n then return i end
  end
end

local sum = 0
for v in range(5) do sum = sum + v end
sum
```
```expected
15
```

---

## Range with step

Example:
```lua
local function range(from, to, step)
  step = step or 1
  local i = from - step
  return function()
    i = i + step
    if i <= to then return i end
  end
end

local out = {}
for v in range(0, 10, 2) do table.insert(out, v) end
table.concat(out, ",")
```
```expected
0,2,4,6,8,10
```

---

## Coroutine-based iterators

`coroutine.wrap` makes complex iteration easy — just `yield` each value:

Example:
```lua
local function tree_values(node)
  return coroutine.wrap(function()
    local function walk(n)
      if type(n) == "table" then
        for _, v in ipairs(n) do walk(v) end
      else
        coroutine.yield(n)
      end
    end
    walk(node)
  end)
end

local result = {}
for v in tree_values({1, {2, 3}, {4, {5, 6}}}) do
  table.insert(result, v)
end
table.concat(result, ",")
```
```expected
1,2,3,4,5,6
```

---

## Filter iterator

Wraps any iterator and skips values that don't match a predicate:

Example:
```lua
local function filter(iter, pred)
  return function()
    while true do
      local v = iter()
      if v == nil then return nil end
      if pred(v) then return v end
    end
  end
end

local function range(n)
  local i = 0
  return function()
    i = i + 1
    if i <= n then return i end
  end
end

local out = {}
for v in filter(range(10), function(x) return x % 2 == 0 end) do
  table.insert(out, v)
end
table.concat(out, ",")
```
```expected
2,4,6,8,10
```

---

## Map iterator

Applies a transform to each yielded value:

Example:
```lua
local function map(t, fn)
  local i = 0
  return function()
    i = i + 1
    if t[i] ~= nil then return fn(t[i]) end
  end
end

local out = {}
for v in map({1,2,3,4}, function(x) return x*x end) do
  table.insert(out, v)
end
table.concat(out, ",")
```
```expected
1,4,9,16
```

---

# Exercises

---

### Exercise 1

Write a `range(from, to, step)` iterator.
Use it to sum all numbers from 1 to 100.
> Tip: closure-based; default step = 1.

```lua
-- your code here
```
```expected
5050
```

---

### Exercise 2

Write a `reverse_ipairs(t)` iterator that yields values from the end.
Iterate {1,2,3,4,5} in reverse and concat with ",".
> Tip: start at #t and count down.

```lua
-- your code here
```
```expected
5,4,3,2,1
```

---

### Exercise 3

Write a `zip(a, b)` iterator that yields (val_from_a, val_from_b) pairs.
Zip {1,2,3} and {4,5,6} and sum ALL yielded values.
> Tip: track a shared index; stop when either table runs out.

```lua
-- your code here
```
```expected
21
```

---

### Exercise 4

Write a `take(iter, n)` wrapper that stops the iterator after n values.
Wrap a range(1, 1000) and take 5 values. Return their sum.
> Tip: closure that counts down; returns nil when count reaches 0.

```lua
-- your code here
```
```expected
15
```

---

### Exercise 5 — Challenge

Write a `lines(s)` iterator that yields each line from a multi-line string.
Iterate "one\ntwo\nthree" and return the lines joined by "|".
> Tip: use string.gmatch with pattern "[^\n]+".

```lua
-- your code here
```
```expected
one|two|three
```
