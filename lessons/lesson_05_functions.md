# Lesson 05: Functions

The reference manual states: *"Functions are first-class values in Lua.
This means that functions can be stored in variables, passed as arguments
to other functions, and returned as results."*

Every function in Lua is a *closure*: it captures references to the
variables in its enclosing scope (called *upvalues*). This is true even
for top-level functions, which have upvalues from the global environment.

---

## 1. Defining Functions

Two syntaxes, both equivalent:

```lua
-- Statement form (syntactic sugar)
local function add(a, b)
  return a + b
end

-- Expression form
local add = function(a, b)
  return a + b
end
```

Example:
```lua
local function square(x)
  return x * x
end
square(7)
```
```expected
49
```

---

## 2. Functions as Values

Because functions are first-class values, they can be stored in tables,
passed as arguments, and returned from other functions:

Example:
```lua
local ops = {
  add = function(a, b) return a + b end,
  sub = function(a, b) return a - b end,
  mul = function(a, b) return a * b end,
}
ops.mul(6, 7)
```
```expected
42
```

---

## 3. Multiple Return Values

Lua functions can return multiple values using a comma-separated list
after `return`. This avoids the need for output parameters or wrapper tables.

Example:
```lua
local function divmod(a, b)
  return a // b, a % b
end
local q, r = divmod(17, 5)
tostring(q) .. " remainder " .. tostring(r)
```
```expected
3 remainder 2
```

---

### Adjustment of multiple returns

When a multi-return call is not at the end of an expression list, it is
*adjusted to one value*. Only the last call in a list preserves all values:

Example:
```lua
local function two() return 1, 2 end
local a, b, c = two(), 3   -- two() adjusted to 1 (not at end)
tostring(a) .. tostring(b) .. tostring(c)
```
```expected
133
```

---

Example:
```lua
local function two() return 1, 2 end
local a, b, c = 0, two()   -- two() at end: all values kept
tostring(a) .. tostring(b) .. tostring(c)
```
```expected
012
```

---

## 4. Variadic Functions

`...` captures any number of extra arguments. It can be used in
expressions, passed to other functions, or packed into a table:

Example:
```lua
local function sum(...)
  local total = 0
  for _, v in ipairs({...}) do
    total = total + v
  end
  return total
end
sum(1, 2, 3, 4, 5)
```
```expected
15
```

---

### select()

`select(n, ...)` returns all arguments from position `n` onwards.
`select('#', ...)` returns the total count of arguments:

Example:
```lua
local function count(...)
  return select('#', ...)
end
count(10, nil, 30, nil)   -- counts nil arguments too!
```
```expected
4
```

---

Example:
```lua
local function third(...)
  return select(3, ...)
end
third("a", "b", "c", "d")
```
```expected
c
```

---

### table.pack

`table.pack(...)` packs arguments into a table with a `.n` field for the count:

Example:
```lua
local function show_args(...)
  local t = table.pack(...)
  return t.n
end
show_args(10, 20, 30)
```
```expected
3
```

---

## 5. Closures and Upvalues

A closure captures the *variables* (not just values) of its enclosing scope.
When the variable changes, the closure sees the new value:

Example:
```lua
local function make_counter(start)
  local n = start
  return {
    inc = function() n = n + 1 end,
    get = function() return n end,
  }
end
local c = make_counter(10)
c.inc()
c.inc()
c.inc()
c.get()
```
```expected
13
```

---

### Shared upvalues

Two closures in the same scope share the same upvalue:

Example:
```lua
local function make_pair()
  local shared = 0
  local function set(v) shared = v end
  local function get() return shared end
  return set, get
end
local set, get = make_pair()
set(42)
get()
```
```expected
42
```

---

## 6. Higher-Order Functions

Functions that take functions as arguments or return functions:

Example:
```lua
local function map(t, fn)
  local result = {}
  for i, v in ipairs(t) do
    result[i] = fn(v)
  end
  return result
end
local doubled = map({1,2,3,4,5}, function(x) return x*2 end)
table.concat(doubled, ",")
```
```expected
2,4,6,8,10
```

---

Example:
```lua
local function filter(t, fn)
  local result = {}
  for _, v in ipairs(t) do
    if fn(v) then table.insert(result, v) end
  end
  return result
end
local evens = filter({1,2,3,4,5,6}, function(x) return x%2==0 end)
table.concat(evens, ",")
```
```expected
2,4,6
```

---

Example:
```lua
local function reduce(t, fn, init)
  local acc = init
  for _, v in ipairs(t) do
    acc = fn(acc, v)
  end
  return acc
end
reduce({1,2,3,4,5}, function(a, b) return a+b end, 0)
```
```expected
15
```

---

## 7. Function Composition

Example:
```lua
local function compose(f, g)
  return function(...)
    return f(g(...))
  end
end
local double = function(x) return x * 2 end
local inc    = function(x) return x + 1 end
local double_then_inc = compose(inc, double)
double_then_inc(5)
```
```expected
11
```

---

## 8. Memoization

Caching expensive function results:

Example:
```lua
local function memoize(fn)
  local cache = {}
  return function(n)
    if cache[n] == nil then
      cache[n] = fn(n)
    end
    return cache[n]
  end
end

local calls = 0
local slow_square = function(x)
  calls = calls + 1
  return x * x
end
local fast_square = memoize(slow_square)
fast_square(5)
fast_square(5)   -- cached
fast_square(5)   -- cached
calls            -- only called once
```
```expected
1
```

---

## 9. Recursion

Example:
```lua
local function factorial(n)
  if n <= 1 then return 1 end
  return n * factorial(n - 1)
end
factorial(10)
```
```expected
3628800
```

---

### Tail calls

A *tail call* is a function call that is the last action of the calling function.
Lua performs *tail call optimization* (TCO): tail calls do not add a stack frame.
This allows tail-recursive functions to run without stack overflow:

```lua
-- This will NOT overflow (tail recursive)
local function sum_tail(n, acc)
  acc = acc or 0
  if n == 0 then return acc end
  return sum_tail(n - 1, acc + n)   -- tail call
end
```

Example:
```lua
local function sum_tail(n, acc)
  acc = acc or 0
  if n == 0 then return acc end
  return sum_tail(n - 1, acc + n)
end
sum_tail(100)
```
```expected
5050
```

---

## 10. Currying and Partial Application

Example:
```lua
local function partial(fn, ...)
  local outer_args = {...}
  return function(...)
    local args = {}
    for _, v in ipairs(outer_args) do table.insert(args, v) end
    for _, v in ipairs({...})      do table.insert(args, v) end
    return fn(table.unpack(args))
  end
end

local add = function(a, b) return a + b end
local add5 = partial(add, 5)
add5(10)
```
```expected
15
```

---

---

# Exercises

---

### Exercise 1 — Basic function

Write a function `clamp(x, lo, hi)` that returns x clamped to [lo, hi].
Call it with clamp(15, 0, 10).
> Tip: use math.min and math.max.

```lua
-- your code here
```
```expected
10
```

---

### Exercise 2 — Multiple returns

Write a function `stats(t)` that returns the minimum, maximum, and
sum of a sequence. Call it on {3,1,4,1,5,9,2,6} and return just the max.
> Tip: return three values.

```lua
-- your code here
```
```expected
9
```

---

### Exercise 3 — Variadic

Write a `max(...)` function that returns the maximum of all its arguments.
Call it with max(3, 1, 4, 1, 5, 9, 2, 6).
> Tip: iterate with select or {...}.

```lua
-- your code here
```
```expected
9
```

---

### Exercise 4 — Closure counter

Write `make_counter(start, step)` that returns a function which increments
by `step` each call. Start at 0, step 3. Call it 4 times and return the result.
> Tip: n = n + step; return n.

```lua
-- your code here
```
```expected
12
```

---

### Exercise 5 — map

Use a `map` function to convert {"1","2","3","4"} to numbers.
Return their sum.
> Tip: tonumber in the map callback.

```lua
-- your code here
```
```expected
10
```

---

### Exercise 6 — filter

Filter a list of numbers keeping only those divisible by 3.
Input: {1,2,3,4,5,6,7,8,9,10,11,12}.
Return the sum of the filtered list.
> Tip: n % 3 == 0 in the filter predicate.

```lua
-- your code here
```
```expected
42
```

---

### Exercise 7 — reduce

Use reduce to find the product of all numbers in {1,2,3,4,5}.
> Tip: accumulate with multiplication; start with 1.

```lua
-- your code here
```
```expected
120
```

---

### Exercise 8 — once

Write a function `once(fn)` that returns a wrapper that calls `fn` only
on the first invocation, returning nil thereafter.
> Tip: use a closure with a boolean flag.

```lua
local calls = 0
local fn = once(function() calls = calls + 1; return calls end)
fn()
fn()
fn()
calls
```
```expected
1
```

---

### Exercise 9 — Compose chain

Compose three functions: double(x)=x*2, square(x)=x^2, inc(x)=x+1.
Apply them in order: double then square then inc to the value 3.
> Tip: compose left-to-right: result = inc(square(double(x))).

```lua
-- your code here
```
```expected
37
```

---

### Exercise 10 — Challenge: pipeline

Write a `pipeline(fns)` function that takes a list of functions and
returns a new function that applies them all in sequence.
Build a pipeline of: trim whitespace, uppercase, reverse.
Test on "  hello  ".
> Tip: use table of functions and reduce with function application.

```lua
local function pipeline(fns)
  -- your code here
end
local process = pipeline({
  function(s) return s:match("^%s*(.-)%s*$") end,  -- trim
  function(s) return s:upper() end,
  function(s) return s:reverse() end,
})
process("  hello  ")
```
```expected
OLLEH
```
