# Lesson 12: Modules and require

Lua's module system is built on a single function: `require`. The reference
manual says: *"The require function loads the given module. The function
starts by looking into the package.loaded table to determine whether modname
is already loaded. If it is, then require returns the value stored at
package.loaded[modname]. Otherwise, it tries to find a loader for the module."*

This design means modules are singletons: the first `require` runs the file,
every subsequent call returns the cached result.

---

## 1. What is a Module?

A module is a Lua file that returns a value — usually a table. The returned
table contains the module's public interface:

```lua
-- mymodule.lua
local M = {}

function M.greet(name)
  return "hello, " .. name
end

return M   -- <-- this is what require() returns
```

Example:
```lua
-- Simulating a module inline
local M = {}
function M.double(x) return x * 2 end
function M.square(x) return x * x end

-- What the "user" does:
M.double(7)
```
```expected
14
```

---

## 2. require and package.loaded

`require("name")` returns the cached value from `package.loaded["name"]`
if it exists. Otherwise it finds and runs the module file, stores the
result in `package.loaded`, and returns it.

You can interact with this cache directly:

Example:
```lua
-- Manually populate the cache
package.loaded["mymod"] = { version = "1.0", name = "mymod" }
local m = require("mymod")
m.version
```
```expected
1.0
```

---

Example:
```lua
-- Verify require returns the cached value
package.loaded["same"] = { x = 42 }
local a = require("same")
local b = require("same")
a == b   -- same table reference
```
```expected
true
```

---

## 3. Unloading a Module

Set `package.loaded[name] = nil` to force a fresh load on next `require`:

Example:
```lua
package.loaded["reload_test"] = { loaded = true }
package.loaded["reload_test"] = nil
package.loaded["reload_test"]
```
```expected
nil
```

---

## 4. package.path

`package.path` is a semicolon-separated string of patterns Lua searches.
`?` is replaced by the module name, with `.` converted to `/`:

Example:
```lua
-- package.path is always a string
type(package.path)
```
```expected
string
```

---

Example:
```lua
-- It contains ? placeholders
package.path:find("?") ~= nil
```
```expected
true
```

---

## 5. The M Pattern (Standard Module)

The standard Lua module pattern:

Example:
```lua
local M = {}

-- Private (not in M table)
local _count = 0

-- Public
function M.increment()
  _count = _count + 1
end

function M.get()
  return _count
end

M.increment()
M.increment()
M.increment()
M.get()
```
```expected
3
```

---

## 6. Lazy Initialization

Defer expensive work until first use:

Example:
```lua
local M = {}
local _data = nil

local function load_data()
  if not _data then
    -- expensive operation simulated here
    _data = { items = {1, 2, 3, 4, 5}, loaded = true }
  end
  return _data
end

function M.get_items()
  return load_data().items
end

#M.get_items()
```
```expected
5
```

---

## 7. The setup() Pattern

Used universally in Neovim plugins. The module has a `defaults` table and
a `setup(opts)` that merges user options:

Example:
```lua
local M = {}

M.defaults = {
  timeout  = 1000,
  retries  = 3,
  debug    = false,
  prefix   = "[plugin]",
}

M._config = nil

function M.setup(opts)
  M._config = vim.tbl_deep_extend("force", M.defaults, opts or {})
end

function M.config()
  return M._config or vim.deepcopy(M.defaults)
end

M.setup({ retries = 5, debug = true })

-- timeout preserved from defaults
M.config().timeout
```
```expected
1000
```

---

## 8. Submodules

Large plugins split into sub-files under a directory:

```
myplugin/
  init.lua       ← require("myplugin")
  config.lua     ← require("myplugin.config")
  core.lua       ← require("myplugin.core")
```

Example:
```lua
-- Simulate a submodule:
package.loaded["myplugin.config"] = {
  get = function() return { width = 80 } end
}
package.loaded["myplugin"] = {
  config = require("myplugin.config")
}
require("myplugin").config.get().width
```
```expected
80
```

---

## 9. Safe require with pcall

When a module might not be installed (e.g. an optional plugin):

Example:
```lua
local ok, mod = pcall(require, "nonexistent_module_xyz")
ok
```
```expected
false
```

---

Example:
```lua
-- Pattern: safe_require returns nil on failure
local function safe_require(name)
  local ok, result = pcall(require, name)
  return ok and result or nil
end

local m = safe_require("nonexistent_xyz")
m == nil
```
```expected
true
```

---

## 10. Module with Singleton State

Example:
```lua
local Registry = {}
Registry.__index = Registry

local _instance = nil

function Registry.get_instance()
  if not _instance then
    _instance = setmetatable({ _items = {} }, Registry)
  end
  return _instance
end

function Registry:register(name, value)
  self._items[name] = value
end

function Registry:lookup(name)
  return self._items[name]
end

local r1 = Registry.get_instance()
local r2 = Registry.get_instance()
r1:register("key", 42)
r2:lookup("key")   -- same instance
```
```expected
42
```

---

## 11. Autoload Pattern

Defer loading submodules until first access:

Example:
```lua
local M = {}

local loaded = {}
local sub_modules = {
  utils  = { trim = function(s) return s:match("^%s*(.-)%s*$") end },
  format = { upper = function(s) return s:upper() end },
}

setmetatable(M, {
  __index = function(t, k)
    if sub_modules[k] then
      loaded[k] = sub_modules[k]
      rawset(t, k, loaded[k])
      return loaded[k]
    end
  end
})

M.utils.trim("  hello  ")
```
```expected
hello
```

---

---

# Exercises

---

### Exercise 1 — Cache check

Store a value in package.loaded, require it, and verify it's the same table.
Return true if `require("test_mod") == package.loaded["test_mod"]`.
> Tip: package.loaded is just a regular table.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 2 — Private state

Create a module with a private counter and two public functions:
`inc()` and `val()`. Increment 5 times and return val().
> Tip: the counter is a local variable outside the M table.

```lua
-- your code here
```
```expected
5
```

---

### Exercise 3 — setup() merge

Create a module with defaults `{ a=1, b=2, c=3 }`.
Call setup with `{ b=99 }`. Return the value of `a` (should be default).
> Tip: vim.tbl_deep_extend("force", defaults, opts).

```lua
-- your code here
```
```expected
1
```

---

### Exercise 4 — safe_require

Write a `safe_require` function that returns `nil` if the module doesn't exist.
Call it on a non-existent module and return `m == nil`.
> Tip: pcall(require, name).

```lua
-- your code here
```
```expected
true
```

---

### Exercise 5 — Reload simulation

Populate package.loaded["mymod"] with `{v=1}`. Read v.
Then set package.loaded["mymod"] = {v=2} to "reload".
Read v again and return it.
> Tip: mutating package.loaded simulates reloading.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 6 — Submodule

Simulate a plugin with a submodule. Store `{value=42}` in
`package.loaded["myplugin.data"]`. Access it from a "parent" module
and return the value.
> Tip: require("myplugin.data").value.

```lua
-- your code here
```
```expected
42
```

---

### Exercise 7 — Challenge: registry

Build a module registry that allows registering and listing modules by name.
Register "parser", "renderer", "formatter".
Return the count of registered modules.
> Tip: keep a private table; expose register(name) and count() functions.

```lua
-- your code here
```
```expected
3
```
