# Lesson 04: Tables

Tables are the only compound data structure in Lua. The reference manual says:
*"Tables are the main (and only) data structuring mechanism in Lua, and a
powerful one. We use tables to represent ordinary arrays, sequences, symbol
tables, sets, records, graphs, trees, and many other data structures."*

A table is an associative array: it maps keys to values. Keys can be any
value except `nil` and `NaN`. Integer keys starting at 1 form a *sequence*
(the array part), which has an efficient contiguous representation.

---

## 1. Creating Tables

Example:
```lua
local empty = {}
type(empty)
```
```expected
table
```

---

### Array constructor

Example:
```lua
local fruits = { "apple", "banana", "cherry" }
fruits[2]
```
```expected
banana
```

---

### Record constructor

Example:
```lua
local person = { name = "Ada", age = 36, lang = "Lua" }
person.name
```
```expected
Ada
```

---

### Mixed constructor

Example:
```lua
local t = { 10, 20, x = 30, 40 }
-- array part: t[1]=10, t[2]=20, t[3]=40
-- hash part:  t.x=30
tostring(t[1]) .. "," .. tostring(t[2]) .. "," .. tostring(t[3])
```
```expected
10,20,40
```

---

### Explicit integer keys

Example:
```lua
local t = { [1] = "a", [3] = "c", [2] = "b" }
t[2]
```
```expected
b
```

---

## 2. Accessing Fields

There are two syntaxes for field access, which are equivalent:

```lua
t["key"]   -- bracket notation — works for any key
t.key      -- dot notation — syntactic sugar for string keys only
```

Example:
```lua
local t = { hello = "world" }
t["hello"] == t.hello
```
```expected
true
```

---

Example:
```lua
-- Dot notation requires a valid identifier key
local t = { ["my-key"] = 99 }
t["my-key"]   -- must use brackets
```
```expected
99
```

---

## 3. Table Length with #

`#t` returns the *border* of a sequence: any index where `t[i] ~= nil`
and `t[i+1] == nil`. For sequences without holes, this is the last index.

**Warning:** `#` gives undefined results for tables with holes (gaps in
integer keys). Always use tables without gaps if you need a reliable length.

Example:
```lua
local t = {10, 20, 30, 40, 50}
#t
```
```expected
5
```

---

## 4. table.insert and table.remove

`table.insert(t, [pos,] value)` inserts a value (default: at the end).
`table.remove(t, [pos])` removes and returns a value (default: the last).

Example:
```lua
local t = {1, 2, 3}
table.insert(t, 4)
#t
```
```expected
4
```

---

Example:
```lua
local t = {1, 2, 3, 4}
table.insert(t, 2, 99)  -- insert at position 2
table.concat(t, ",")
```
```expected
1,99,2,3,4
```

---

Example:
```lua
local t = {1, 2, 3, 4, 5}
local removed = table.remove(t)   -- removes last
tostring(removed) .. " / " .. tostring(#t)
```
```expected
5 / 4
```

---

Example:
```lua
local t = {1, 2, 3, 4, 5}
table.remove(t, 2)   -- removes index 2
table.concat(t, ",")
```
```expected
1,3,4,5
```

---

## 5. table.sort

`table.sort(t, [comp])` sorts a sequence in-place. The optional comparator
function `comp(a, b)` must return `true` if `a < b`.

Example:
```lua
local t = {5, 3, 1, 4, 2}
table.sort(t)
table.concat(t, " ")
```
```expected
1 2 3 4 5
```

---

Example:
```lua
-- Custom comparator: sort descending
local t = {5, 3, 1, 4, 2}
table.sort(t, function(a, b) return a > b end)
table.concat(t, " ")
```
```expected
5 4 3 2 1
```

---

Example:
```lua
-- Sort strings by length
local t = { "banana", "fig", "apple", "kiwi" }
table.sort(t, function(a, b) return #a < #b end)
table.concat(t, " ")
```
```expected
fig kiwi apple banana
```

---

## 6. table.concat

`table.concat(t, sep, i, j)` joins a sequence into a string.
Much faster than repeated `..` for large arrays.

Example:
```lua
local t = {"a", "b", "c", "d"}
table.concat(t, "-")
```
```expected
a-b-c-d
```

---

Example:
```lua
-- With range
local t = {"a", "b", "c", "d", "e"}
table.concat(t, ",", 2, 4)
```
```expected
b,c,d
```

---

## 7. Iterating Tables

### ipairs — sequential (array) iteration

`ipairs(t)` iterates indices 1, 2, 3, ... stopping at the first nil:

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

### pairs — all keys

`pairs(t)` iterates all keys in undefined order:

Example:
```lua
local counts = {}
local t = { x=1, y=2, z=3 }
for k, v in pairs(t) do
  counts[k] = v * 2
end
counts.y
```
```expected
4
```

---

### next() — low-level iteration

`next(t, key)` returns the next key-value pair after `key` (nil to start).
`pairs` is built on `next`:

Example:
```lua
local t = { a = 1 }
local k, v = next(t, nil)   -- first pair
tostring(k) .. "=" .. tostring(v)
```
```expected
a=1
```

---

## 8. table.unpack

`table.unpack(t, i, j)` expands a sequence into multiple return values.
This is the inverse of collecting `...` into a table.

Example:
```lua
local t = {10, 20, 30}
local a, b, c = table.unpack(t)
b
```
```expected
20
```

---

Example:
```lua
-- With range
local t = {1, 2, 3, 4, 5}
local a, b, c = table.unpack(t, 2, 4)
tostring(a) .. tostring(b) .. tostring(c)
```
```expected
234
```

---

## 9. table.move

`table.move(a1, f, e, t, a2)` copies elements from `a1[f..e]` to `a2[t..]`.
If `a2` is omitted, it defaults to `a1`:

Example:
```lua
local t = {1, 2, 3, 4, 5}
local dst = {}
table.move(t, 2, 4, 1, dst)
table.concat(dst, ",")
```
```expected
2,3,4
```

---

## 10. Nested Tables

Tables can contain other tables, forming trees and complex structures:

Example:
```lua
local matrix = {
  {1, 2, 3},
  {4, 5, 6},
  {7, 8, 9},
}
matrix[2][3]
```
```expected
6
```

---

Example:
```lua
local config = {
  server = { host = "localhost", port = 8080 },
  debug = true,
}
config.server.port
```
```expected
8080
```

---

## 11. Tables as Sets

Since keys are unique, tables naturally implement sets:

Example:
```lua
local set = {}
for _, v in ipairs({"apple", "banana", "apple", "cherry"}) do
  set[v] = true
end
-- count unique elements
local count = 0
for _ in pairs(set) do count = count + 1 end
count
```
```expected
3
```

---

## 12. Stack and Queue patterns

Example:
```lua
-- Stack (LIFO): insert/remove at end
local stack = {}
table.insert(stack, "a")
table.insert(stack, "b")
table.insert(stack, "c")
table.remove(stack)   -- pop
table.concat(stack, "")
```
```expected
ab
```

---

Example:
```lua
-- Queue (FIFO): insert at end, remove from front
local queue = {}
table.insert(queue, "first")
table.insert(queue, "second")
table.insert(queue, "third")
table.remove(queue, 1)   -- dequeue
queue[1]
```
```expected
second
```

---

---

# Exercises

---

### Exercise 1 — Construction

Create a table representing a book: title="Lua Manual", pages=320, year=2024.
Return the number of pages.
> Tip: use the record constructor `{ key = value }`.

```lua
-- your code here
```
```expected
320
```

---

### Exercise 2 — insert/remove

Start with `{1, 2, 3, 4, 5}`. Remove the middle element (index 3) and
insert 99 at the beginning. Return the resulting string with table.concat.
> Tip: table.remove(t, 3) then table.insert(t, 1, 99).

```lua
-- your code here
```
```expected
99,1,2,4,5
```

---

### Exercise 3 — sort

Sort `{"banana", "apple", "cherry", "date"}` alphabetically and return
the first element.
> Tip: table.sort in-place, then t[1].

```lua
-- your code here
```
```expected
apple
```

---

### Exercise 4 — Set operations

Given two sets A and B (as tables with boolean values), find their intersection
(keys present in both). Return the count of elements in the intersection.
> Tip: iterate one set and check if each key exists in the other.

```lua
local A = { x=true, y=true, z=true }
local B = { y=true, z=true, w=true }
-- your code here
```
```expected
2
```

---

### Exercise 5 — Nested access

Given a deeply nested table, safely access a value that might not exist.
Return the value if it exists, "missing" if any level is nil.
> Tip: use `and` chaining: `t.a and t.a.b and t.a.b.c or "missing"`.

```lua
local data = { user = { profile = { score = 42 } } }
-- your code here (access data.user.profile.score)
```
```expected
42
```

---

### Exercise 6 — Frequency count

Count the frequency of each word in {"the","cat","sat","on","the","mat","the"}.
Return the count for "the".
> Tip: use a table as a counter: freq[word] = (freq[word] or 0) + 1.

```lua
local words = {"the","cat","sat","on","the","mat","the"}
-- your code here
```
```expected
3
```

---

### Exercise 7 — Flatten

Flatten `{1, {2, 3}, {4, {5, 6}}}` into a single array `{1,2,3,4,5,6}`.
Return table.concat of the result with ",".
> Tip: use a recursive function that checks type(v) == "table".

```lua
-- your code here
```
```expected
1,2,3,4,5,6
```

---

### Exercise 8 — table.move (copy)

Use table.move to copy the subarray from index 3 to 6 of
`{10,20,30,40,50,60,70}` into a new table.
Return the first element of the new table.
> Tip: table.move(src, 3, 6, 1, dst).

```lua
-- your code here
```
```expected
30
```

---

### Exercise 9 — unpack into function

Given `local args = {5, 3}`, pass them to `math.max` using `table.unpack`.
> Tip: math.max(table.unpack(args)).

```lua
local args = {5, 3, 8, 1}
-- your code here
```
```expected
8
```

---

### Exercise 10 — Challenge: group by

Given a list of items each with a `category` field, group them into a
table of lists keyed by category. Return the count of items in the "fruit" group.

```lua
local items = {
  { name="apple",  category="fruit" },
  { name="carrot", category="veggie" },
  { name="banana", category="fruit" },
  { name="pear",   category="fruit" },
  { name="broccoli", category="veggie" },
}
-- your code here
```
```expected
3
```
