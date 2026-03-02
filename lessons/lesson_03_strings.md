# Lesson 03: Strings

Lua strings are immutable sequences of bytes. They can contain any byte
value including embedded NUL bytes. The reference manual notes that Lua
is "8-bit clean": strings are not unicode-aware by default — they operate
on bytes, not characters.

Strings are *interned*: equal string literals share memory. This makes
`==` comparison O(1), and is why strings are immutable (mutation would
break the interning invariant).

> All string functions are also available as *methods* via the string
> metatable: `s:upper()` is the same as `string.upper(s)`.

---

## 1. String Literals

Example:
```lua
local a = "double quotes"
local b = 'single quotes'
a == b
```
```expected
false
```

---

### Long strings with [[ ]]

Long strings begin with `[[` and end with `]]`. They span multiple lines
and perform **no escape processing**:

Example:
```lua
local s = [[
line one
line two]]
-- Note: leading newline after [[ is ignored
s:sub(1, 9)
```
```expected
line one
```

---

### Escape sequences

| Sequence | Meaning |
|----------|---------|
| `\n` | newline |
| `\t` | tab |
| `\\` | backslash |
| `\"` | double quote |
| `\'` | single quote |
| `\r` | carriage return |
| `\0` | NUL byte |
| `\xHH` | hex byte |
| `\ddd` | decimal byte (0-255) |

Example:
```lua
"tab:\there\nnewline"
```
```expected
tab:	here
newline
```

---

## 2. Concatenation and Length

Example:
```lua
local first = "Lua"
local last = "JIT"
first .. " " .. last
```
```expected
Lua JIT
```

---

Example:
```lua
#"Neovim rocks!"
```
```expected
14
```

---

> **Performance note:** chaining many `..` creates intermediate strings.
> For building large strings, collect pieces in a table and use
> `table.concat(parts)` — this is the idiomatic Lua pattern.

Example:
```lua
local parts = {}
for i = 1, 5 do
  parts[i] = tostring(i)
end
table.concat(parts, "-")
```
```expected
1-2-3-4-5
```

---

## 3. string.format

`string.format(fmt, ...)` is like C's `printf`. It is the standard way
to build formatted strings:

| Spec | Meaning |
|------|---------|
| `%s` | string |
| `%d` | integer |
| `%f` | float |
| `%g` | shortest float representation |
| `%x` | lowercase hex |
| `%X` | uppercase hex |
| `%q` | quoted string (safe for Lua source) |
| `%%` | literal `%` |
| `%05d` | zero-padded 5 digits |
| `%-10s` | left-aligned, 10 wide |

Example:
```lua
string.format("Hello, %s! You are %d years old.", "Ada", 36)
```
```expected
Hello, Ada! You are 36 years old.
```

---

Example:
```lua
string.format("Pi is approximately %.4f", math.pi)
```
```expected
Pi is approximately 3.1416
```

---

Example:
```lua
string.format("%08x", 255)
```
```expected
000000ff
```

---

Example:
```lua
string.format("%-10s|%10s", "left", "right")
```
```expected
left      |     right
```

---

## 4. Case Conversion

Example:
```lua
string.upper("hello world")
```
```expected
HELLO WORLD
```

---

Example:
```lua
string.lower("NEOVIM")
```
```expected
neovim
```

---

## 5. Substrings

`string.sub(s, i, j)` returns the substring from index `i` to `j` (inclusive).
Indices start at 1. Negative indices count from the end (`-1` is the last byte).

Example:
```lua
string.sub("hello world", 7)
```
```expected
world
```

---

Example:
```lua
string.sub("hello world", 1, 5)
```
```expected
hello
```

---

Example:
```lua
string.sub("hello", -3)   -- last 3 bytes
```
```expected
llo
```

---

## 6. Finding and Matching

`string.find(s, pattern, init, plain)` returns the start and end positions.
`string.match(s, pattern)` returns the captured text.

Example:
```lua
local s, e = string.find("hello world", "world")
tostring(s) .. "-" .. tostring(e)
```
```expected
7-11
```

---

Example:
```lua
string.match("2024-03-15", "%d+")   -- first match
```
```expected
2024
```

---

Example:
```lua
-- Captures with ()
local y, m, d = string.match("2024-03-15", "(%d+)-(%d+)-(%d+)")
y .. "/" .. m .. "/" .. d
```
```expected
2024/03/15
```

---

### Plain mode

Pass `true` as the 4th argument to `string.find` to disable pattern
matching and do a literal substring search:

Example:
```lua
local s, e = string.find("1+2=3", "+", 1, true)
tostring(s)
```
```expected
2
```

---

## 7. string.gmatch — iterate over all matches

`string.gmatch(s, pattern)` returns an iterator that yields each match:

Example:
```lua
local words = {}
for w in string.gmatch("one two three", "%a+") do
  table.insert(words, w)
end
table.concat(words, "|")
```
```expected
one|two|three
```

---

Example:
```lua
-- With captures
local pairs_found = {}
for k, v in string.gmatch("a=1, b=2, c=3", "(%a)=(%d)") do
  table.insert(pairs_found, k .. ":" .. v)
end
table.concat(pairs_found, " ")
```
```expected
a:1 b:2 c:3
```

---

## 8. string.gsub — replace

`string.gsub(s, pattern, repl, n)` replaces matches. `repl` can be:
- a string (with `%0`=whole match, `%1`=first capture, etc.)
- a function (called with each match/captures, return value is replacement)
- a table (match/capture used as key, return value is replacement)

Returns the new string AND the number of replacements made.

Example:
```lua
string.gsub("hello world", "(%a+)", function(w) return w:upper() end)
```
```expected
HELLO WORLD
```

---

Example:
```lua
-- Table replacement
local vars = { name = "Lua", version = "5.4" }
string.gsub("$name v$version", "%$(%a+)", vars)
```
```expected
Lua v5.4
```

---

Example:
```lua
-- Count replacements (second return value)
local result, count = string.gsub("banana", "a", "o")
tostring(count)
```
```expected
3
```

---

Example:
```lua
-- Limit replacements with 4th argument
string.gsub("banana", "a", "o", 2)
```
```expected
bonona
```

---

## 9. string.rep, string.reverse

Example:
```lua
string.rep("ab", 4, "-")   -- with separator
```
```expected
ab-ab-ab-ab
```

---

Example:
```lua
string.reverse("Neovim")
```
```expected
mivoeN
```

---

## 10. string.byte and string.char

`string.byte(s, i, j)` returns the byte values at positions i through j.
`string.char(...)` converts byte values back to a string.

Example:
```lua
string.byte("A")
```
```expected
65
```

---

Example:
```lua
string.char(65, 66, 67)
```
```expected
ABC
```

---

Example:
```lua
-- All bytes of "Lua"
string.byte("Lua", 1, -1)
```
```expected
76
```

---

## 11. String as method syntax

Any string function can be called as a method because strings have a
metatable with `__index = string`:

Example:
```lua
("hello world"):upper():sub(1, 5)
```
```expected
HELLO
```

---

---

# Exercises

---

### Exercise 1 — Format

Format the number 3.14159 to exactly 2 decimal places.
> Tip: use `%.2f` format spec.

```lua
-- your code here
```
```expected
3.14
```

---

### Exercise 2 — Sub

Extract "world" from "hello world".
> Tip: string.sub with start index 7.

```lua
local s = "hello world"
-- your code here
```
```expected
world
```

---

### Exercise 3 — Find

Return the start position of "lua" in "I love lua programming".
> Tip: string.find returns start, end positions.

```lua
local s = "I love lua programming"
-- your code here
```
```expected
8
```

---

### Exercise 4 — gmatch words

Count the number of words in "the quick brown fox jumps over the lazy dog".
> Tip: iterate with `%a+` and increment a counter.

```lua
local s = "the quick brown fox jumps over the lazy dog"
-- your code here
```
```expected
9
```

---

### Exercise 5 — gsub

Replace all vowels in "hello world" with "*".
> Tip: use gsub with a character set `[aeiou]`.

```lua
-- your code here
```
```expected
h*ll* w*rld
```

---

### Exercise 6 — Table concat

Build the string "1, 2, 3, 4, 5" by collecting numbers into a table and
using table.concat.
> Tip: tostring each number, insert into parts, then table.concat with ", ".

```lua
-- your code here
```
```expected
1, 2, 3, 4, 5
```

---

### Exercise 7 — Parse CSV row

Parse "Alice,30,Engineer" into separate values using gmatch.
Return just the second field (age).
> Tip: use gmatch with `[^,]+` to match non-comma sequences.

```lua
local row = "Alice,30,Engineer"
-- your code here
```
```expected
30
```

---

### Exercise 8 — byte/char

Convert the string "Hi" to its byte values and back.
Return the reconstructed string.
> Tip: string.byte then string.char.

```lua
-- your code here
```
```expected
Hi
```

---

### Exercise 9 — Padding

Format the number 42 as a zero-padded 6-digit string.
> Tip: use `%06d`.

```lua
-- your code here
```
```expected
000042
```

---

### Exercise 10 — Challenge: title case

Write a function `title_case(s)` that capitalizes the first letter of each word.
Test on "the quick brown fox".
> Tip: use gsub with `%a+` pattern and return first byte upcased + rest.

```lua
-- your code here
```
```expected
The Quick Brown Fox
```
