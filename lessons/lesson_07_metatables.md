# Lesson 07: Metatables and Metamethods

The Lua reference manual describes metatables as: "Every value in Lua can
have a metatable. This metatable is an ordinary Lua table that defines the
behavior of the original value under certain special operations."

Metatables enable operator overloading, custom indexing, and callable tables.

---

## setmetatable / getmetatable

`setmetatable(t, mt)` attaches `mt` as the metatable of `t`.
Only tables can have metatables set from Lua (userdata metatables are set from C):

Example:
```lua
local t = {}
local mt = { __name = "MyTable" }
setmetatable(t, mt)
getmetatable(t) == mt
```
```expected
true
```

---

## __index — lookup fallback

When a key is missing from a table, Lua checks `__index`.
If `__index` is a table, Lua looks there:

Example:
```lua
local defaults = { color = "red", size = 10, visible = true }
local obj = setmetatable({}, { __index = defaults })
obj.color
```
```expected
red
```

---

## __index as a function

`__index` can be a function `(table, key) -> value` for dynamic lookup:

Example:
```lua
local env = setmetatable({}, {
  __index = function(t, k)
    return "undefined: " .. k
  end
})
env.foo
```
```expected
undefined: foo
```

---

## __newindex — intercept writes

`__newindex(t, k, v)` fires when writing to a key that does NOT already
exist in the table. Use `rawset` to actually store the value:

Example:
```lua
local log = {}
local t = setmetatable({}, {
  __newindex = function(tbl, k, v)
    table.insert(log, k .. "=" .. tostring(v))
    rawset(tbl, k, v)
  end
})
t.x = 10
t.y = 20
table.concat(log, "|")
```
```expected
x=10|y=20
```

---

## rawget / rawset

Bypass metamethods — directly access/set the table:

Example:
```lua
local t = setmetatable({}, {
  __index = function(_, k) return "meta:" .. k end
})
rawget(t, "missing")   -- bypasses __index, returns nil
```
```expected
nil
```

---

## __tostring

Called by `tostring()` and string formatting:

Example:
```lua
local mt = {
  __tostring = function(t)
    return string.format("[%s, %s]", t[1], t[2])
  end
}
tostring(setmetatable({"hello", "world"}, mt))
```
```expected
[hello, world]
```

---

## Arithmetic metamethods

| Metamethod | Operator |
|------------|----------|
| `__add` | `+` |
| `__sub` | `-` |
| `__mul` | `*` |
| `__div` | `/` |
| `__mod` | `%` |
| `__pow` | `^` |
| `__unm` | unary `-` |
| `__idiv` | `//` |

Example:
```lua
local Vec = {}
Vec.__index = Vec
Vec.__add = function(a, b)
  return setmetatable({x = a.x+b.x, y = a.y+b.y}, Vec)
end
Vec.__tostring = function(v) return "("..v.x..","..v.y..")" end
local v = setmetatable({x=1,y=2}, Vec)
  + setmetatable({x=3,y=4}, Vec)
tostring(v)
```
```expected
(4,6)
```

---

## __eq, __lt, __le

Comparison metamethods. Note: `__eq` only fires when both values have
the same metamethod (or are the same table):

Example:
```lua
local Mt = {}
Mt.__index = Mt
Mt.__eq = function(a, b) return a.value == b.value end
local a = setmetatable({value = 42}, Mt)
local b = setmetatable({value = 42}, Mt)
a == b
```
```expected
true
```

---

## __len

Overrides the `#` operator:

Example:
```lua
local t = setmetatable({1, 2, 3}, {
  __len = function(t) return 999 end
})
#t
```
```expected
999
```

---

## __concat

Overrides the `..` operator:

Example:
```lua
local mt = {
  __concat = function(a, b)
    return setmetatable({value = a.value .. b.value}, getmetatable(a))
  end,
  __tostring = function(a) return a.value end
}
local s1 = setmetatable({value = "hello"}, mt)
local s2 = setmetatable({value = " world"}, mt)
tostring(s1 .. s2)
```
```expected
hello world
```

---

## __call — callable tables

`__call` makes a table behave like a function:

Example:
```lua
local Adder = setmetatable({}, {
  __call = function(self, a, b)
    return a + b
  end
})
Adder(10, 32)
```
```expected
42
```

---

## __index chain (inheritance)

When `__index` itself has a metatable with `__index`, lookups chain:

Example:
```lua
local A = { x = 1 }
local B = setmetatable({ y = 2 }, { __index = A })
local C = setmetatable({ z = 3 }, { __index = B })
C.x  -- walks: C → B → A
```
```expected
1
```

---

## Read-only tables

Use `__newindex` + `__index` on a proxy table to make immutable tables:

Example:
```lua
local function readonly(t)
  return setmetatable({}, {
    __index = t,
    __newindex = function(_, k, v)
      error("attempt to update a read-only table", 2)
    end
  })
end
local ro = readonly({ x = 10 })
local ok = pcall(function() ro.x = 20 end)
ok
```
```expected
false
```

---

# Exercises

---

### Exercise 1

Create a table that returns 0 for any missing numeric key.
Access t[99] and return it.
> Tip: __index as a function that returns 0.

```lua
-- your code here
```
```expected
0
```

---

### Exercise 2

Create two vectors {x=3, y=4} and {x=1, y=2} with __sub metamethod.
Return the x component of their difference.
> Tip: __sub(a, b) should return a new vector table.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 3

Make a callable table that multiplies its two arguments.
Call it with 6 and 7.
> Tip: __call receives the table itself as first arg.

```lua
-- your code here
```
```expected
42
```

---

### Exercise 4

Create a "tracked" table that counts every write to it.
Write 5 values and return the write count.
> Tip: use __newindex with rawset plus a counter in the metatable.

```lua
-- your code here
```
```expected
5
```

---

### Exercise 5 — Challenge

Implement a class system function `class(parent)` that:
- Returns a new class table
- Sets up __index for inheritance from parent (if given)
- Has a :new(...) method that creates instances
Test: class() → Animal, class(Animal) → Dog; Dog inherits Animal.speak.

```lua
-- your code here
```
```expected
Dog says woof
```
