# Lesson 23: Writing Your Neovim Config

This lesson covers the patterns used in real `init.lua` configurations.
We go from the very basic structure to advanced patterns like lazy-loading,
conditional platform config, and filetype-specific settings.

---

## The init.lua entry point

Neovim loads `~/.config/nvim/init.lua` on startup. There is no
`vimrc` needed. A well-organized config splits into modules:

```
~/.config/nvim/
  init.lua              ← entry point
  lua/
    config/
      options.lua       ← vim.opt settings
      keymaps.lua       ← vim.keymap.set calls
      autocmds.lua      ← autocommand groups
      lazy.lua          ← plugin manager bootstrap
    plugins/
      telescope.lua     ← plugin specs
      lsp.lua
      treesitter.lua
```

---

## Leader key — set before everything

The leader key must be set before any keymaps that reference it:

Example:
```lua
vim.g.mapleader = " "
vim.g.maplocalleader = "\\"
vim.g.mapleader
```
```expected
 
```

---

## Applying options in a loop

Example:
```lua
local options = {
  -- editing
  expandtab    = true,
  tabstop      = 2,
  shiftwidth   = 2,
  smartindent  = true,
  -- UI
  number         = true,
  relativenumber = true,
  cursorline     = true,
  signcolumn     = "yes",
  -- search
  ignorecase = true,
  smartcase  = true,
  -- misc
  splitbelow = true,
  splitright = true,
}
for k, v in pairs(options) do
  vim.opt[k] = v
end
vim.opt.tabstop:get()
```
```expected
2
```

---

## vim.opt_local in FileType autocmds

The correct way to apply per-filetype settings:

Example:
```lua
local g = vim.api.nvim_create_augroup("MyFtConfig", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "markdown",
  group = g,
  callback = function()
    vim.opt_local.textwidth = 80
    vim.opt_local.wrap = true
    vim.opt_local.spell = true
  end,
})
#vim.api.nvim_get_autocmds({ group = g })
```
```expected
1
```

---

## OS detection

Example:
```lua
local is_win  = vim.fn.has("win32")  == 1
local is_mac  = vim.fn.has("mac")    == 1
local is_linux = vim.fn.has("unix")  == 1 and not is_mac
type(is_linux)
```
```expected
boolean
```

---

## GUI detection

Example:
```lua
local is_gui = vim.fn.has("gui_running") == 1
if is_gui then
  vim.opt.guifont = "JetBrainsMono Nerd Font:h13"
end
type(is_gui)
```
```expected
boolean
```

---

## stdpath — standard paths

`vim.fn.stdpath(what)` returns standard Neovim directories:

| what | returns |
|------|---------|
| `"config"` | `~/.config/nvim` |
| `"data"` | `~/.local/share/nvim` |
| `"cache"` | `~/.cache/nvim` |
| `"state"` | `~/.local/state/nvim` |
| `"log"` | log directory |

Example:
```lua
type(vim.fn.stdpath("config"))
```
```expected
string
```

---

## Checking plugin availability before configuring

Example:
```lua
local ok, telescope = pcall(require, "telescope")
if ok then
  -- telescope.setup({ ... })
end
type(ok)
```
```expected
boolean
```

---

## vim.schedule — deferred execution

`vim.schedule(fn)` runs `fn` after the current event loop tick.
Used to defer work until Neovim is fully initialized:

Example:
```lua
local ran = false
vim.schedule(function() ran = true end)
-- It hasn't run yet here (it's deferred), but the function is registered
type(vim.schedule)
```
```expected
function
```

---

## vim.defer_fn — time-delayed execution

`vim.defer_fn(fn, ms)` runs `fn` after `ms` milliseconds:

Example:
```lua
type(vim.defer_fn)
```
```expected
function
```

---

## require with error handling for modules

In init.lua, use a wrapper so one bad plugin doesn't break everything:

Example:
```lua
local function safe_require(mod)
  local ok, m = pcall(require, mod)
  if not ok then
    vim.notify("Could not load: " .. mod, vim.log.levels.WARN)
    return nil
  end
  return m
end
type(safe_require("string"))
```
```expected
table
```

---

## Conditional keymap setup

Register keymaps only when the relevant plugin is loaded:

Example:
```lua
local ok, _ = pcall(require, "nonexistent_plugin_xyz")
if ok then
  vim.keymap.set("n", "<leader>f", function() end, {})
end
-- The keymap was not registered because the plugin is missing
local found = false
for _, m in ipairs(vim.api.nvim_get_keymap("n")) do
  if m.lhs == " f" then found = true end
end
found
```
```expected
false
```

---

## vim.notify — user messages

`vim.notify(msg, level, opts)` shows a notification:

| Level | Constant |
|-------|---------|
| 0 | `vim.log.levels.TRACE` |
| 1 | `vim.log.levels.DEBUG` |
| 2 | `vim.log.levels.INFO` |
| 3 | `vim.log.levels.WARN` |
| 4 | `vim.log.levels.ERROR` |

Example:
```lua
type(vim.notify)
```
```expected
function
```

---

## Autocmd for "post-init" work

`VimEnter` fires after init.lua completes — good for deferred setup:

Example:
```lua
local g = vim.api.nvim_create_augroup("PostInit", { clear = true })
vim.api.nvim_create_autocmd("VimEnter", {
  group = g,
  once = true,
  callback = function()
    -- Runs after everything is loaded
  end,
})
#vim.api.nvim_get_autocmds({ group = g })
```
```expected
1
```

---

## colorscheme and StatusLine

Setting colourscheme and customizing the status line:

Example:
```lua
-- Set a fallback colorscheme that always exists
vim.cmd.colorscheme("default")
type(vim.g.colors_name)
```
```expected
string
```

---

# Exercises

---

### Exercise 1

Set your leader to space and confirm vim.g.mapleader.
> Tip: vim.g.mapleader = " ".

```lua
-- your code here
```
```expected
 
```

---

### Exercise 2

Apply a table of 3 options with a loop. Return the tabstop value.
> Tip: for k, v in pairs(opts) do vim.opt[k] = v end.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 3

Write a `safe_require(mod)` that returns the module or nil on failure.
Call it with "string" and return the type of the result.
> Tip: pcall(require, mod).

```lua
-- your code here
```
```expected
table
```

---

### Exercise 4

Register a FileType autocmd for "lua" that sets tabstop to 2.
Return the count of autocmds in the group.
> Tip: nvim_create_augroup + nvim_create_autocmd with FileType pattern.

```lua
-- your code here
```
```expected
1
```

---

### Exercise 5

Get the config path with stdpath("config") and return its type.
> Tip: vim.fn.stdpath("config").

```lua
-- your code here
```
```expected
string
```

---

### Exercise 6 — Challenge

Write a `configure(spec)` function that accepts a table like:
```lua
{
  options = { tabstop=2, number=true },
  keymaps = { {"n","<F1>",function()end,{}} },
}
```
and applies all options and keymaps. Call it, then return vim.opt.tabstop:get().
> Tip: loop options with vim.opt[k]=v; loop keymaps with vim.keymap.set.

```lua
-- your code here
```
```expected
2
```
