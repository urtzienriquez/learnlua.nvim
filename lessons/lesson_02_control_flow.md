# Lesson 02: Control Flow

Lua's control structures are: `if`, `while`, `repeat/until`, and `for`
(in two flavours: numeric and generic). Lua also has `break`, `goto`,
and uses `do...end` blocks for explicit scope control.

> From the reference manual: *"Lua is a free-form language. It ignores
> spaces (including new lines) and comments between lexical elements."*
> Semicolons are optional statement separators.

---

## 1. if / elseif / else

```
if condition then
  body
elseif condition2 then
  body
else
  body
end
```

Conditions can be any expression. Remember: only `nil` and `false` are falsy.

Example:
```lua
local x = 10
if x > 5 then
  return "big"
else
  return "small"
end
```
```expected
big
```

---

Example:
```lua
local score = 75
local grade
if score >= 90 then
  grade = "A"
elseif score >= 80 then
  grade = "B"
elseif score >= 70 then
  grade = "C"
elseif score >= 60 then
  grade = "D"
else
  grade = "F"
end
grade
```
```expected
C
```

---

### if as an expression (using and/or)

Lua has no ternary `?:` operator, but the `and`/`or` idiom works:

Example:
```lua
local n = 7
local result = (n % 2 == 0) and "even" or "odd"
result
```
```expected
odd
```

---

## 2. while

```
while condition do
  body
end
```

The condition is checked *before* each iteration. If false initially, the body
never runs.

Example:
```lua
local i = 1
local sum = 0
while i <= 5 do
  sum = sum + i
  i = i + 1
end
sum
```
```expected
15
```

---

## 3. repeat / until

```
repeat
  body
until condition
```

The condition is checked *after* each iteration, so the body always runs
at least once. Variables declared inside the body are visible in the
`until` condition — this is unique to `repeat/until` in Lua.

Example:
```lua
local i = 1
local result = 0
repeat
  result = result + i
  i = i + 1
until i > 5
result
```
```expected
15
```

---

Example:
```lua
-- Variables declared inside repeat are visible in until
local found = false
local tries = 0
repeat
  tries = tries + 1
  local ok = (tries == 3)  -- declared inside
until ok                    -- ok is visible here!
tries
```
```expected
3
```

---

## 4. Numeric for

```
for var = start, limit, step do
  body
end
```

`step` defaults to 1. The loop variable `var` is local to the loop body.
**Never assign to the loop variable inside the loop** — it has no effect.
The limit and step are evaluated once before the loop starts.

Example:
```lua
local sum = 0
for i = 1, 10 do
  sum = sum + i
end
sum
```
```expected
55
```

---

Example:
```lua
-- Counting down with negative step
local result = {}
for i = 5, 1, -1 do
  table.insert(result, i)
end
table.concat(result, ", ")
```
```expected
5, 4, 3, 2, 1
```

---

Example:
```lua
-- Step other than 1
local result = {}
for i = 0, 10, 2 do
  table.insert(result, i)
end
table.concat(result, " ")
```
```expected
0 2 4 6 8 10
```

---

## 5. Generic for

```
for var1, var2, ... in iter_function do
  body
end
```

The generic `for` works with any iterator. `ipairs` iterates arrays by index;
`pairs` iterates all key-value pairs. See lesson 08 for the full internals.

Example:
```lua
local sum = 0
for i, v in ipairs({10, 20, 30}) do
  sum = sum + v
end
sum
```
```expected
60
```

---

Example:
```lua
-- pairs iterates all keys (order not guaranteed for non-integer keys)
local t = { a = 1, b = 2, c = 3 }
local sum = 0
for k, v in pairs(t) do
  sum = sum + v
end
sum
```
```expected
6
```

---

## 6. break

`break` exits the innermost loop immediately:

Example:
```lua
local found = nil
for i = 1, 100 do
  if i * i > 50 then
    found = i
    break
  end
end
found
```
```expected
8
```

---

## 7. goto and labels

Lua has `goto label` for jumping to a `::label::`. It is mainly used to
simulate `continue` (skip the rest of the loop body):

Example:
```lua
-- Simulate "continue": skip odd numbers
local result = {}
for i = 1, 8 do
  if i % 2 ~= 0 then goto continue end
  table.insert(result, i)
  ::continue::
end
table.concat(result, ", ")
```
```expected
2, 4, 6, 8
```

---

## 8. do ... end blocks (explicit scope)

`do...end` creates an explicit scope. Variables declared inside are local
to the block and freed when the block ends:

Example:
```lua
local result = "outer"
do
  local result = "inner"  -- shadows the outer 'result'
  -- inner result is "inner" here
end
result  -- back to the outer result
```
```expected
outer
```

---

## 9. Nested loops and break

`break` only exits the *innermost* loop. To break multiple levels,
use `goto` or a flag variable:

Example:
```lua
local found_i, found_j
for i = 1, 5 do
  for j = 1, 5 do
    if i * j == 12 then
      found_i, found_j = i, j
      goto done
    end
  end
end
::done::
tostring(found_i) .. "x" .. tostring(found_j)
```
```expected
3x4
```

---

## 10. Scope rules

Lua uses *lexical scoping*. A local variable is visible from its
declaration to the end of the block that contains it:

Example:
```lua
local x = 1
do
  local x = 2    -- new variable, shadows outer x
  do
    local x = 3  -- another new variable
  end
  -- x is 2 here
  return x
end
```
```expected
2
```

---

---

# Exercises

---

### Exercise 1 — if/elseif

Write a function `classify(n)` that returns:
- "negative" if n < 0
- "zero" if n == 0
- "small" if 0 < n <= 10
- "large" if n > 10

Call it with 7.
> Tip: use if/elseif/else.

```lua
-- your code here
```
```expected
small
```

---

### Exercise 2 — while

Use a `while` loop to find the first power of 2 that is greater than 1000.
> Tip: start with n=1 and double it each iteration.

```lua
-- your code here
```
```expected
1024
```

---

### Exercise 3 — repeat/until

Use `repeat/until` to read from a sequence until you find a value > 50.
Given `local nums = {10, 20, 35, 60, 90}`, return the first value > 50
and the index where it was found.
> Tip: use a counter inside repeat; the until condition sees the counter.

```lua
local nums = {10, 20, 35, 60, 90}
-- your code here
```
```expected
60
```

---

### Exercise 4 — Numeric for

Use a numeric for loop to compute the sum of squares: 1² + 2² + ... + 10².
> Tip: sum = sum + i*i.

```lua
-- your code here
```
```expected
385
```

---

### Exercise 5 — Generic for

Use ipairs to build a string from {"a","b","c","d"} where each element
is prefixed by its 1-based index: "1:a, 2:b, 3:c, 4:d".
> Tip: build up with table.concat after collecting into a list.

```lua
-- your code here
```
```expected
1:a, 2:b, 3:c, 4:d
```

---

### Exercise 6 — break

Find the first index in {5, 3, 8, 1, 9, 2, 7} where the value exceeds 7.
Return that index.
> Tip: use a for loop and break when found.

```lua
-- your code here
```
```expected
5
```

---

### Exercise 7 — goto (continue)

Use goto to skip multiples of 3 when building a list from 1 to 12.
Return the sum of the non-multiples.
> Tip: `if i % 3 == 0 then goto continue end` then `::continue::` at end of loop body.

```lua
-- your code here
```
```expected
40
```

---

### Exercise 8 — Scope

Predict and return the value of `x` after the following block.
Set `x` to 10 outside, then inside a `do` block set `local x = 99`.
Return the outer `x`.
> Tip: `local` inside `do` creates a new scope.

```lua
-- your code here
```
```expected
10
```

---

### Exercise 9 — Nested loops

Find all pairs (i, j) where 1 <= i <= j <= 5 and i + j == 7.
Return them as a string in the format "2+5, 3+4" (sorted).
> Tip: use two nested for loops.

```lua
-- your code here
```
```expected
2+5, 3+4
```

---

### Exercise 10 — Challenge: FizzBuzz

Write FizzBuzz for numbers 1 to 20:
- "Fizz" for multiples of 3
- "Buzz" for multiples of 5
- "FizzBuzz" for multiples of both
- the number itself otherwise

Return the result for n=15.
> Tip: check FizzBuzz first (divisible by both), then Fizz, then Buzz, then number.

```lua
local function fizzbuzz(n)
  -- your code here
end
fizzbuzz(15)
```
```expected
FizzBuzz
```
