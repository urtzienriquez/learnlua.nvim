# Lesson 06: Object-Oriented Programming

Lua has no built-in class system. Instead, the Lua reference manual says:
"The table type implements associative arrays... Tables can also carry
methods by storing functions in their fields."

OOP in Lua is built on two mechanisms: tables as objects, and metatables
to define class-like behaviour. This is not a limitation — it is a
deliberate design that lets you build exactly the OOP model you need.

---

## Objects as tables

The simplest object: a table with data and functions:

Example:
```lua
local dog = {
  name = "Rex",
  speak = function(self)
    return self.name .. " says woof!"
  end
}
dog:speak()
```
```expected
Rex says woof!
```

---

## The class pattern

The standard idiom sets the table as its own metatable index,
so all instances share methods but have their own data:

Example:
```lua
local Animal = {}
Animal.__index = Animal

function Animal.new(name, sound)
  return setmetatable({ name = name, sound = sound }, Animal)
end

function Animal:speak()
  return self.name .. " says " .. self.sound
end

Animal.new("Cat", "meow"):speak()
```
```expected
Cat says meow
```

---

## Why __index = Animal

When you access `obj.speak`, Lua:
1. Looks in `obj` → not found
2. Checks `getmetatable(obj).__index` → that's `Animal`
3. Looks in `Animal` → finds `speak`

This is how instances share class methods without copying them:

Example:
```lua
local Dog = {}
Dog.__index = Dog
function Dog.new(n) return setmetatable({name=n}, Dog) end
function Dog:name_upper() return self.name:upper() end

local d = Dog.new("buddy")
d:name_upper()
```
```expected
BUDDY
```

---

## Instance data vs class data

Class-level fields are shared. Instance-level fields are per-object:

Example:
```lua
local Counter = {}
Counter.__index = Counter
Counter.class_name = "Counter"   -- shared by all instances

function Counter.new(n)
  return setmetatable({ count = n or 0 }, Counter)
end

local c = Counter.new(5)
c.class_name .. " | " .. c.count
```
```expected
Counter | 5
```

---

## Method chaining

Return `self` from methods to enable fluent APIs:

Example:
```lua
local Builder = {}
Builder.__index = Builder

function Builder.new()
  return setmetatable({ parts = {} }, Builder)
end

function Builder:add(s)
  table.insert(self.parts, s)
  return self
end

function Builder:build()
  return table.concat(self.parts, " ")
end

Builder.new():add("Lua"):add("is"):add("fun"):build()
```
```expected
Lua is fun
```

---

## Inheritance

A subclass sets its `__index` to look up the parent:

Example:
```lua
-- Base class
local Shape = {}
Shape.__index = Shape
function Shape.new(color)
  return setmetatable({ color = color }, Shape)
end
function Shape:getColor() return self.color end

-- Subclass
local Circle = setmetatable({}, { __index = Shape })
Circle.__index = Circle
function Circle.new(color, r)
  local self = Shape.new(color)
  self.radius = r
  return setmetatable(self, Circle)
end
function Circle:area()
  return math.floor(math.pi * self.radius ^ 2)
end

local c = Circle.new("blue", 5)
c:getColor() .. " | area=" .. c:area()
```
```expected
blue | area=78
```

---

## super() pattern

Calling the parent's method from a child:

Example:
```lua
local Base = {}
Base.__index = Base
function Base.new() return setmetatable({log={}}, Base) end
function Base:init() table.insert(self.log, "base-init") end

local Child = setmetatable({}, { __index = Base })
Child.__index = Child
function Child:init()
  Base.init(self)   -- call parent
  table.insert(self.log, "child-init")
end

local obj = setmetatable(Base.new(), Child)
obj:init()
table.concat(obj.log, ",")
```
```expected
base-init,child-init
```

---

## instanceof check

Example:
```lua
local Cat = {}
Cat.__index = Cat
function Cat.new() return setmetatable({}, Cat) end

local function instanceof(obj, class)
  return getmetatable(obj) == class
end

local c = Cat.new()
instanceof(c, Cat)
```
```expected
true
```

---

## __tostring

Example:
```lua
local Point = {}
Point.__index = Point
Point.__tostring = function(p)
  return string.format("(%d, %d)", p.x, p.y)
end
function Point.new(x, y)
  return setmetatable({x=x, y=y}, Point)
end
tostring(Point.new(3, 7))
```
```expected
(3, 7)
```

---

# Exercises

---

### Exercise 1

Create a `Stack` class with `push(v)`, `pop()`, and `size()` methods.
Push "a", "b", "c", pop once, return size.
> Tip: store items in self.items; use table.insert and table.remove.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 2

Create a `BankAccount` with `deposit(n)`, `withdraw(n)` (refuse if balance
would go negative, return false), and `balance()`.
Deposit 100, withdraw 40, try to withdraw 200, return balance().
> Tip: check self._balance >= n before withdrawing.

```lua
-- your code here
```
```expected
60
```

---

### Exercise 3

Create `Vehicle` with `describe()` returning "Vehicle: name".
Create `Car` extending `Vehicle` overriding `describe()` to return "Car: name".
Return Car.new("Tesla"):describe().
> Tip: setmetatable(Car, { __index = Vehicle }).

```lua
-- your code here
```
```expected
Car: Tesla
```

---

### Exercise 4

Use method chaining to build the string "SELECT * FROM users WHERE id = 1"
using a QueryBuilder class with select(), from(), where() methods.
> Tip: each method sets a field on self and returns self.

```lua
-- your code here
```
```expected
SELECT * FROM users WHERE id = 1
```

---

### Exercise 5 — Challenge

Implement a simple event emitter with `on(event, fn)` and `emit(event, ...)`.
Register two listeners for "data", emit with value 42, and return the sum
of both listener results.
> Tip: store listeners[event] as a list; emit calls each one.

```lua
-- your code here
```
```expected
84
```
