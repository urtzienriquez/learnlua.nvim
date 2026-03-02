# Lesson 09: Patterns and String Matching

Lua has its own pattern language — not POSIX regex. The Lua reference
manual describes it as "a simplified regular expression alternative".
It lacks alternation (`|`) and backtracking, but covers most real needs
with much simpler rules.

---

## Character classes

| Class | Matches |
|-------|---------|
| `.` | any character |
| `%a` | letters (a-z, A-Z) |
| `%l` | lowercase letters |
| `%u` | uppercase letters |
| `%d` | digits (0-9) |
| `%w` | alphanumeric (%a + %d) |
| `%s` | whitespace (space, tab, newline, etc.) |
| `%p` | punctuation |
| `%c` | control characters |
| `%x` | hexadecimal digits |
| `%z` | the zero byte |

Uppercase versions are the complement: `%A` = non-letter, `%D` = non-digit, etc.

Example:
```lua
string.match("hello123", "%d+")
```
```expected
123
```

---

## Quantifiers

| Quantifier | Meaning |
|------------|---------|
| `+` | one or more (greedy) |
| `*` | zero or more (greedy) |
| `?` | zero or one |
| `-` | zero or more (non-greedy / lazy) |

The difference between `*` and `-`:

Example:
```lua
-- Greedy: matches as much as possible
string.match("<tag>content</tag>", "<(.+)>")
```
```expected
tag>content</tag
```

Example:
```lua
-- Non-greedy: matches as little as possible
string.match("<tag>content</tag>", "<(.-)>")
```
```expected
tag
```

---

## Anchors

`^` anchors to start of string. `$` anchors to end:

Example:
```lua
string.match("hello", "^h")
```
```expected
h
```

Example:
```lua
string.match("hello", "o$")
```
```expected
o
```

Example:
```lua
-- Full match
string.match("hello", "^hello$")
```
```expected
hello
```

---

## Character sets [...]

`[abc]` matches any of a, b, c. `[^abc]` matches anything else.
Ranges: `[a-z]`, `[0-9]`:

Example:
```lua
string.match("hello", "[aeiou]")   -- first vowel
```
```expected
e
```

Example:
```lua
string.match("abc123", "[^%a]+")   -- first non-letter sequence
```
```expected
123
```

---

## Captures with ()

Parentheses define captures. `string.match` returns them:

Example:
```lua
local user, domain = string.match("alice@example.com", "(.+)@(.+)")
user .. " at " .. domain
```
```expected
alice at example.com
```

---

## Multiple captures

Example:
```lua
local y, m, d = string.match("2024-03-15", "(%d%d%d%d)-(%d%d)-(%d%d)")
d .. "/" .. m .. "/" .. y
```
```expected
15/03/2024
```

---

## string.find

Returns start, end positions (and captures if any).
`plain = true` treats the pattern as a literal string:

Example:
```lua
local s, e = string.find("hello world", "world")
s .. "-" .. e
```
```expected
7-11
```

Example:
```lua
-- Returning captures too
local s, e, cap = string.find("foo=bar", "(%w+)$")
cap
```
```expected
bar
```

---

## string.gmatch

Iterates over all non-overlapping matches:

Example:
```lua
local words = {}
for w in string.gmatch("the quick brown fox", "%a+") do
  table.insert(words, w)
end
#words
```
```expected
4
```

Example:
```lua
-- Key-value pairs
local t = {}
for k, v in string.gmatch("x=1,y=2,z=3", "(%w+)=(%w+)") do
  t[k] = tonumber(v)
end
t.x + t.y + t.z
```
```expected
6
```

---

## string.gsub — replacement

`string.gsub(s, pattern, repl, n)` — repl can be a string, table, or function.
In string replacements, `%0` = whole match, `%1` = first capture, etc:

Example:
```lua
-- String replacement with captures
string.gsub("hello world", "(%w+)", "[%1]")
```
```expected
[hello] [world]
```

Example:
```lua
-- Function replacement
string.gsub("1 + 2 = ?", "%d+", function(n)
  return tostring(tonumber(n) * 2)
end)
```
```expected
2 + 4 = ?
```

Example:
```lua
-- Table replacement
local t = { name = "Lua", year = "1993" }
string.gsub("$name was created in $year", "%$(%w+)", t)
```
```expected
Lua was created in 1993
```

---

## Escaping special chars

Escape with `%`. Special pattern chars: `( ) . % + - * ? [ ^ $`:

Example:
```lua
string.match("price: $3.99", "%$%d+%.%d+")
```
```expected
$3.99
```

---

## Position capture ()

An empty capture `()` returns the current position in the string:

Example:
```lua
local pos = string.find("hello world", "()", 7)
pos
```
```expected
7
```

---

# Exercises

---

### Exercise 1

Extract the protocol from a URL "https://example.com/path".
Return "https".
> Tip: match everything before "://".

```lua
local url = "https://example.com/path"
-- your code here
```
```expected
https
```

---

### Exercise 2

Count all digits in the string "a1b2c3d4e5".
> Tip: use gmatch with %d.

```lua
local s = "a1b2c3d4e5"
-- your code here
```
```expected
5
```

---

### Exercise 3

Replace all runs of whitespace with a single space and trim the result.
Input: "  hello   world  "
> Tip: gsub %s+ with " ", then match the trimmed content.

```lua
local s = "  hello   world  "
-- your code here
```
```expected
hello world
```

---

### Exercise 4

Parse "key1=val1;key2=val2;key3=val3" into a table.
Return the value for "key2".
> Tip: gmatch with (%w+)=(%w+) pattern.

```lua
local s = "key1=val1;key2=val2;key3=val3"
-- your code here
```
```expected
val2
```

---

### Exercise 5

Validate that a string is a valid integer (only digits, optionally
preceded by a minus sign). Return true for "-42" and false for "12.5".
> Tip: match("^-?%d+$") returns nil if it doesn't match.

```lua
local function is_integer(s)
  -- your code here
end
tostring(is_integer("-42")) .. "," .. tostring(is_integer("12.5"))
```
```expected
true,false
```

---

### Exercise 6 — Challenge

Write a simple `template(s, vars)` function that replaces `{{key}}`
placeholders with values from the vars table.
Test with "Hello, {{name}}! You have {{count}} messages."
and vars = { name="Ada", count="3" }.
> Tip: gsub with {{(%w+)}} pattern and a function looking up vars.

```lua
-- your code here
```
```expected
Hello, Ada! You have 3 messages.
```
