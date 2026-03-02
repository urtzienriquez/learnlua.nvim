# Lesson 24: Writing a Neovim Plugin

This lesson covers the complete anatomy of a real Neovim plugin — from
file layout to the public API — using patterns found in popular plugins
like telescope.nvim, nvim-cmp, and neo-tree.nvim.

---

## Plugin file layout

```
myplugin.nvim/
│
├── plugin/
│   └── myplugin.lua        ← auto-sourced at startup (register commands)
│
├── lua/
│   └── myplugin/
│       ├── init.lua        ← public API (require("myplugin"))
│       ├── config.lua      ← default options and setup()
│       ├── core.lua        ← implementation (internal)
│       └── health.lua      ← :checkhealth myplugin
│
├── doc/
│   └── myplugin.txt        ← Vim help file
│
└── README.md
```

`plugin/` files are sourced by Neovim at startup. Keep them minimal —
just register commands, autocommands, and call `require("myplugin")`.
Heavy work goes in `lua/`.

---

## The plugin entry point — plugin/myplugin.lua

Example:
```lua
-- Simulating plugin/myplugin.lua
-- Only runs once; registers the user-facing command
vim.api.nvim_create_user_command("MyPlugin", function(opts)
  require("myplugin").run(opts.args)
end, { nargs = "?" })

vim.api.nvim_get_commands({})["MyPlugin"] ~= nil
```
```expected
true
```

---

## The config module

Stores defaults and merges user options:

Example:
```lua
local Config = {}

Config._defaults = {
  width    = 80,
  height   = 24,
  border   = "rounded",
  debug    = false,
  mappings = {
    close = "q",
    confirm = "<CR>",
  },
}

Config._opts = nil

function Config.setup(opts)
  Config._opts = vim.tbl_deep_extend(
    "force",
    Config._defaults,
    opts or {}
  )
end

function Config.get()
  return Config._opts or vim.deepcopy(Config._defaults)
end

Config.setup({ width = 120, debug = true })

-- Nested default preserved:
Config.get().mappings.close
```
```expected
q
```

---

## vim.tbl_deep_extend

`"force"` means the second table wins on key conflicts.
`"keep"` means the first table wins.
`"error"` raises on conflicts:

Example:
```lua
local a = { x = 1, sub = { y = 2, z = 3 } }
local b = { x = 9, sub = { y = 99 } }
local m = vim.tbl_deep_extend("force", a, b)
-- x overwritten, sub.y overwritten, sub.z kept
m.x .. "/" .. m.sub.y .. "/" .. m.sub.z
```
```expected
9/99/3
```

---

## vim.tbl_extend (shallow)

Shallow merge — replaces entire nested tables rather than merging them:

Example:
```lua
local a = { sub = { x = 1, y = 2 } }
local b = { sub = { x = 99 } }
local m = vim.tbl_extend("force", a, b)
-- sub.y is GONE — shallow replace
tostring(m.sub.y)
```
```expected
nil
```

---

## vim.deepcopy

Creates a fully independent deep clone:

Example:
```lua
local orig = { config = { timeout = 1000, retries = 3 } }
local copy = vim.deepcopy(orig)
copy.config.timeout = 9999
orig.config.timeout   -- unchanged
```
```expected
1000
```

---

## Utility functions from vim.*

Example:
```lua
-- vim.tbl_keys / vim.tbl_values
local t = { a = 1, b = 2, c = 3 }
local keys = vim.tbl_keys(t)
table.sort(keys)
table.concat(keys, ",")
```
```expected
a,b,c
```

Example:
```lua
local t = { "apple", "banana", "cherry", "apricot" }
local a_fruits = vim.tbl_filter(function(s) return s:sub(1,1) == "a" end, t)
table.concat(a_fruits, ",")
```
```expected
apple,apricot
```

Example:
```lua
local doubled = vim.tbl_map(function(n) return n * 2 end, {1,2,3,4,5})
table.concat(doubled, ",")
```
```expected
2,4,6,8,10
```

---

## vim.list_extend

Appends `src` into `dst` in-place:

Example:
```lua
local a = {1,2,3}
vim.list_extend(a, {4,5,6})
table.concat(a, ",")
```
```expected
1,2,3,4,5,6
```

---

## The init.lua public API

Example:
```lua
local M = {}
local _config = { enabled = true, prefix = "[plugin]" }

function M.setup(opts)
  _config = vim.tbl_deep_extend("force", _config, opts or {})
end

function M.is_enabled()
  return _config.enabled == true
end

function M.version()
  return "1.0.0"
end

M.setup({ prefix = "[myplugin]" })
M.version() .. " | " .. tostring(M.is_enabled())
```
```expected
1.0.0 | true
```

---

## Health checks — lua/myplugin/health.lua

`:checkhealth myplugin` is the standard way for users to diagnose issues.
The health module uses `vim.health.*`:

Example:
```lua
-- A minimal health module
local health = {}

function health.check()
  -- vim.health.start("myplugin")
  -- if pcall(require, "some_dep") then
  --   vim.health.ok("some_dep found")
  -- else
  --   vim.health.error("some_dep not found", { "Install with :MasonInstall some_dep" })
  -- end
end

type(health.check)
```
```expected
function
```

---

## Loading guards

`vim.g.loaded_*` flags prevent a plugin from loading twice.
Modern Lua plugins can skip this (require() is idempotent), but
it is still conventional for VimScript-era interop:

Example:
```lua
if vim.g.loaded_myplugin then
  -- already loaded, skip
end
vim.g.loaded_myplugin = 1
vim.g.loaded_myplugin
```
```expected
1
```

---

## Autocommand setup pattern

Group all plugin autocommands under a named group with `clear = true`:

Example:
```lua
local function setup_autocmds()
  local g = vim.api.nvim_create_augroup("MyPlugin_Autocmds", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = { "lua", "vim" },
    group = g,
    callback = function(ev)
      -- set up buffer-local plugin behaviour
    end,
  })

  vim.api.nvim_create_autocmd("BufWritePost", {
    group = g,
    callback = function()
      -- refresh on save
    end,
  })

  return g
end

local g = setup_autocmds()
#vim.api.nvim_get_autocmds({ group = g })
```
```expected
2
```

---

## Keymap setup pattern

Set up all keymaps in one place, buffer-local when possible:

Example:
```lua
local function setup_keymaps(buf)
  local map = function(mode, lhs, rhs, desc)
    vim.keymap.set(mode, lhs, rhs, { buffer = buf, silent = true, desc = desc })
  end
  map("n", "q",     function() end, "MyPlugin: close")
  map("n", "<CR>",  function() end, "MyPlugin: confirm")
  map("n", "?",     function() end, "MyPlugin: help")
end

local buf = vim.api.nvim_create_buf(false, true)
setup_keymaps(buf)
#vim.api.nvim_buf_get_keymap(buf, "n")
```
```expected
3
```

---

## Complete minimal plugin example

Example:
```lua
-- Full minimal plugin in one block (init.lua equivalent)
local MyPlugin = {}
local _state = { count = 0, config = { step = 1 } }

function MyPlugin.setup(opts)
  _state.config = vim.tbl_deep_extend("force", _state.config, opts or {})
end

function MyPlugin.increment()
  _state.count = _state.count + _state.config.step
  return _state.count
end

function MyPlugin.reset()
  _state.count = 0
end

function MyPlugin.get()
  return _state.count
end

MyPlugin.setup({ step = 5 })
MyPlugin.increment()
MyPlugin.increment()
MyPlugin.increment()
MyPlugin.get()
```
```expected
15
```

---

# Exercises

---

### Exercise 1

Use vim.tbl_deep_extend("force", ...) to merge defaults
`{ a=1, b={ x=1, y=2 } }` with `{ b={ x=99 } }`.
Return b.y (should be preserved).
> Tip: nested tables are merged, not replaced.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 2

Use vim.tbl_filter to keep only strings longer than 3 chars
from `{ "hi", "hello", "yo", "world", "ok" }`. Return the count.
> Tip: #s > 3.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 3

Use vim.tbl_map to square every number in {1,2,3,4,5}.
Return the sum.
> Tip: vim.tbl_map(fn, t) returns a new table.

```lua
-- your code here
```
```expected
55
```

---

### Exercise 4

Build a Config module with defaults `{ timeout=1000, retries=3 }`,
a `setup(opts)` function, and a `get()` function.
Call setup({ retries=5 }). Return timeout (should stay 1000).
> Tip: vim.tbl_deep_extend preserves keys not in opts.

```lua
-- your code here
```
```expected
1000
```

---

### Exercise 5

Set up 3 buffer-local keymaps using a helper function.
Return the count of buffer keymaps in "n" mode.
> Tip: vim.api.nvim_buf_get_keymap(buf, "n").

```lua
-- your code here
```
```expected
3
```

---

### Exercise 6 — Challenge

Build a complete mini-plugin with:
- `setup(opts)` merging into defaults { prefix=">>", enabled=true }
- `format(msg)` that returns prefix .. " " .. msg if enabled, else msg
- `disable()` that sets enabled=false

Call setup({ prefix="--" }), call format("hello"), then disable(),
call format("world"). Return both results joined by "|".
> Tip: _config.enabled controls format behaviour.

```lua
-- your code here
```
```expected
-- hello|world
```
