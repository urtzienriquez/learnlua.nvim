# Lesson 01: Lua Basics

Lua is a lightweight, dynamically-typed scripting language designed for
embedding. According to the Lua 5.4 reference manual, it is "a powerful,
efficient, lightweight, embeddable scripting language". Neovim uses LuaJIT
(Lua 5.1 compatible with some 5.2 features) for its configuration and plugin API.

> **Note:** All values in Lua are *first-class* — variables, table fields,
> and function arguments all hold the same kinds of values with no restrictions.

---

## 1. The Eight Basic Types

Lua has exactly eight types. `type(v)` returns the type name as a string.

| Type | Description | Literal example |
|------|-------------|----------------|
| `nil` | absence of a value | `nil` |
| `boolean` | logical true or false | `true`, `false` |
| `number` | integer or floating-point | `42`, `3.14`, `0xff` |
| `string` | immutable byte sequence | `"hello"`, `[[block]]` |
| `table` | associative array (the only data structure) | `{1, 2, 3}` |
| `function` | first-class callable | `function() end` |
| `userdata` | C data pointer (from C extensions) | (from C API) |
| `thread` | coroutine handle | `coroutine.create(f)` |

Example:
```lua
type("hello")
```
```expected
string
```

---

Example:
```lua
type(42)
```
```expected
number
```

---

Example:
```lua
type(nil)
```
```expected
nil
```

---

Example:
```lua
type({})
```
```expected
table
```

---

Example:
```lua
type(print)
```
```expected
function
```

---

## 2. Variables and Assignment

Lua has two kinds of variables: **global** (default) and **local**.
Always prefer `local` — globals are slower and pollute the global table `_G`.

```
local name = value          -- declares a local variable
name = value                -- assigns to an existing variable (or creates a global!)
```

Example:
```lua
local x = 10
local y = 20
x + y
```
```expected
30
```

---

### Multiple assignment

Lua allows assigning multiple values in one statement.
Extra values are discarded; missing values become nil.

Example:
```lua
local a, b, c = 1, 2, 3
b
```
```expected
2
```

---

Example:
```lua
local a, b = 1, 2, 3   -- 3 is discarded
a + b
```
```expected
3
```

---

Example:
```lua
local a, b, c = 1, 2   -- c becomes nil
c == nil
```
```expected
true
```

---

### Swap idiom

Multiple assignment makes swapping trivial — the right side is evaluated
*before* any assignment happens:

Example:
```lua
local a, b = 10, 20
a, b = b, a
tostring(a) .. "/" .. tostring(b)
```
```expected
20/10
```

---

## 3. Nil and the Absence of Value

`nil` is the only value of its type. It means "no value" or "not present".
Assigning `nil` to a variable effectively removes it.
Any variable that has not been assigned is `nil`.

Example:
```lua
local x
x == nil
```
```expected
true
```

---

Example:
```lua
local t = { a = 1 }
t.b == nil
```
```expected
true
```

---

## 4. Booleans and Truthiness

Lua's boolean values are `true` and `false`.
**Crucially**, only `nil` and `false` are falsy. Everything else —
including `0`, `""`, and `{}` — is truthy. This is different from many
other languages!

Example:
```lua
-- 0 is truthy in Lua!
if 0 then
  return "truthy"
else
  return "falsy"
end
```
```expected
truthy
```

---

Example:
```lua
-- Empty string is truthy
if "" then return "truthy" else return "falsy" end
```
```expected
truthy
```

---

Example:
```lua
-- Only nil and false are falsy
if nil then return "truthy" else return "falsy" end
```
```expected
falsy
```

---

### Boolean operators: and, or, not

`and` and `or` return one of their operands (not necessarily a boolean).
This is because they use *short-circuit evaluation*:

- `a and b` → returns `a` if `a` is falsy, otherwise returns `b`
- `a or b` → returns `a` if `a` is truthy, otherwise returns `b`

Example:
```lua
-- "and" returns first falsy or last value
1 and 2
```
```expected
2
```

---

Example:
```lua
false and 2
```
```expected
false
```

---

Example:
```lua
-- "or" returns first truthy or last value
nil or "default"
```
```expected
default
```

---

Example:
```lua
-- Classic default-value idiom
local x = nil
local result = x or "fallback"
result
```
```expected
fallback
```

---

Example:
```lua
-- Ternary idiom: condition and val_if_true or val_if_false
-- (only safe when val_if_true is never false/nil)
local n = 5
local msg = n > 3 and "big" or "small"
msg
```
```expected
big
```

---

## 5. Numbers

Lua 5.3+ has two numeric subtypes: **integer** and **float**.
In LuaJIT (used by Neovim) all numbers are IEEE 754 doubles, but
integers are represented exactly up to 2^53.

Example:
```lua
-- Integer arithmetic stays integer
type(3 + 4)
```
```expected
number
```

---

Example:
```lua
-- Any float operation makes the result a float
type(3 + 0.0)
```
```expected
number
```

---

### Arithmetic operators

| Operator | Operation | Example |
|----------|-----------|---------|
| `+` | addition | `3 + 4` → `7` |
| `-` | subtraction | `10 - 3` → `7` |
| `*` | multiplication | `3 * 4` → `12` |
| `/` | float division (always float) | `7 / 2` → `3.5` |
| `//` | floor division | `7 // 2` → `3` |
| `%` | modulo | `7 % 3` → `1` |
| `^` | exponentiation (float) | `2 ^ 8` → `256.0` |
| `-` | unary negation | `-5` → `-5` |

Example:
```lua
7 / 2
```
```expected
3.5
```

---

Example:
```lua
7 // 2
```
```expected
3
```

---

Example:
```lua
2 ^ 10
```
```expected
1024.0
```

---

### math library highlights

Example:
```lua
math.max(3, 1, 4, 1, 5, 9, 2, 6)
```
```expected
9
```

---

Example:
```lua
math.floor(3.7)
```
```expected
3
```

---

Example:
```lua
math.abs(-42)
```
```expected
42
```

---

## 6. Strings

Strings in Lua are immutable sequences of bytes. They are *interned* —
equal strings share the same memory, making equality comparison O(1).

String literals can be written with:
- Single quotes: `'hello'`
- Double quotes: `"hello"`
- Long brackets: `[[hello]]` or `[==[hello]==]` (no escape processing)

Example:
```lua
"hello" == 'hello'
```
```expected
true
```

---

### String concatenation with ..

The `..` operator concatenates strings. Numbers are automatically converted:

Example:
```lua
"hello" .. " " .. "world"
```
```expected
hello world
```

---

Example:
```lua
-- Numbers are coerced to strings by ..
"value: " .. 42
```
```expected
value: 42
```

---

### String length with #

Example:
```lua
#"hello"
```
```expected
5
```

---

### tostring and tonumber

`tostring(v)` converts any value to its string representation.
`tonumber(s, base)` parses a string as a number (base defaults to 10):

Example:
```lua
tostring(3.14)
```
```expected
3.14
```

---

Example:
```lua
tonumber("42") + 8
```
```expected
50
```

---

Example:
```lua
tonumber("ff", 16)   -- hex
```
```expected
255
```

---

Example:
```lua
tonumber("not a number")
```
```expected
nil
```

---

## 7. Comparison Operators

| Operator | Meaning |
|----------|---------|
| `==` | equal |
| `~=` | not equal |
| `<` | less than |
| `>` | greater than |
| `<=` | less than or equal |
| `>=` | greater than or equal |

**Important:** `==` never coerces types. `1 == "1"` is `false`.

Example:
```lua
1 == "1"
```
```expected
false
```

---

Example:
```lua
1 ~= 2
```
```expected
true
```

---

## 8. The Global Table _G

All global variables live in the table `_G`. Accessing `_G.x` is the same
as accessing the global `x`. This is useful for dynamic variable names:

Example:
```lua
my_global = 99
_G["my_global"]
```
```expected
99
```

---

Example:
```lua
type(_G)
```
```expected
table
```

---

## 9. String Coercions

Lua automatically coerces strings to numbers in arithmetic, and numbers
to strings in concatenation. However, it is better practice to use
`tonumber` and `tostring` explicitly:

Example:
```lua
"10" + 5   -- string coerced to number
```
```expected
15
```

---

Example:
```lua
-- Concatenation does NOT work directly on numbers without ..
-- But tostring is cleaner than relying on coercion
tostring(100) .. "%"
```
```expected
100%
```

---

## 10. The # Length Operator

`#` returns the length of a string (in bytes) or the border of a sequence table.
For tables with holes (gaps in integer keys), the result is undefined.

Example:
```lua
#"Neovim"
```
```expected
6
```

---

Example:
```lua
#{10, 20, 30, 40}
```
```expected
4
```

---

---

# Exercises

---

### Exercise 1 — Types

Return the type of `true` as a string.
> Tip: use the `type()` function.

```lua
-- your code here
```
```expected
boolean
```

---

### Exercise 2 — Arithmetic

Calculate `(15 + 5) * 3 / 4` using floor division for the final step.
> Tip: use `//` for floor division.

```lua
-- your code here
```
```expected
15
```

---

### Exercise 3 — Truthiness

Return "yes" if `0` is truthy in Lua, otherwise "no".
> Tip: only nil and false are falsy in Lua.

```lua
-- your code here
```
```expected
yes
```

---

### Exercise 4 — Default values

Use the `or` idiom to assign a default value.
Given `local name = nil`, produce the string "anonymous" if name is nil.
> Tip: `name or "default"` returns "default" when name is nil.

```lua
local name = nil
-- your code here
```
```expected
anonymous
```

---

### Exercise 5 — Multiple assignment

Assign the values 10, 20, 30 to a, b, c in a single statement.
Return b.
> Tip: `local a, b, c = ...`

```lua
-- your code here
```
```expected
20
```

---

### Exercise 6 — String length

Return the number of characters in the string "Neovim is great".
> Tip: use the `#` operator.

```lua
-- your code here
```
```expected
15
```

---

### Exercise 7 — tonumber

Convert the string "255" from base 16 (hexadecimal) to a number.
> Tip: `tonumber(s, base)`.

```lua
-- your code here
```
```expected
4294967295
```

---

### Exercise 8 — Swap

Swap the values of two variables in one line without a temporary variable.
Start with a=1, b=2 and return a after the swap.
> Tip: Lua's multiple assignment evaluates the right side first.

```lua
local a, b = 1, 2
-- swap here
a
```
```expected
2
```

---

### Exercise 9 — _G

Store your name in a global variable `author`, then read it back via `_G`.
> Tip: assign to `author` (no local), then return `_G["author"]`.

```lua
-- your code here
```
```expected
your name here
```

---

### Exercise 10 — Challenge: type detective

Write a function `describe(v)` that returns a string like:
- `"nil"` for nil
- `"yes"` for true, `"no"` for false
- the number as a string for numbers
- `"string(N)"` where N is the length for strings
- `"table"` for tables
- `"other"` for anything else

Test it on the string `"hello"`.
> Tip: use if/elseif chains with `type(v)`.

```lua
-- your code here
```
```expected
string(5)
```
