# Lesson 15: Options and Settings

Neovim options control editor behaviour. There are three scopes:
**global** (`:set`), **window-local** (`:setlocal` for windows),
and **buffer-local** (`:setlocal` for buffers).
Lua provides multiple interfaces to set them.

---

## The four interfaces

| Interface | Equivalent | Scope |
|-----------|------------|-------|
| `vim.opt` | `:set` | smart (auto-scopes) |
| `vim.o` | `:set` | global |
| `vim.bo` | `:setlocal` | current buffer |
| `vim.wo` | `:setlocal` | current window |
| `vim.bo[buf]` | | specific buffer |
| `vim.wo[win]` | | specific window |

---

## vim.opt — recommended

`vim.opt` is the high-level, recommended interface.
It handles type coercion and supports list/set operations:

Example:
```lua
vim.opt.number = true
vim.o.number
```
```expected
true
```

---

## vim.opt:get() — reading back as Lua types

`vim.opt.option:get()` returns the value in its Lua-native form
(boolean, number, table, string):

Example:
```lua
vim.opt.tabstop = 4
vim.opt.tabstop:get()
```
```expected
4
```

---

## vim.opt list operations

For comma-separated options (like `path`, `shortmess`, `completeopt`):

Example:
```lua
vim.opt.completeopt = { "menu", "menuone", "noselect" }
local v = vim.opt.completeopt:get()
type(v)
```
```expected
table
```

Example:
```lua
-- Append to a list
vim.opt.shortmess:append("I")
-- Prepend
vim.opt.shortmess:prepend("a")
-- Remove
vim.opt.shortmess:remove("a")
type(vim.opt.shortmess:get())
```
```expected
table
```

---

## vim.o — global scope

Use when you want exactly `:set option=value` semantics:

Example:
```lua
vim.o.laststatus = 2
vim.o.laststatus
```
```expected
2
```

---

## vim.bo — buffer-local

`vim.bo.option` sets the option on the current buffer.
`vim.bo[bufnr].option` sets it on a specific buffer:

Example:
```lua
vim.bo.expandtab = true
vim.bo.expandtab
```
```expected
true
```

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].filetype = "markdown"
vim.bo[buf].filetype
```
```expected
markdown
```

---

## vim.wo — window-local

Example:
```lua
vim.wo.wrap = false
vim.wo.wrap
```
```expected
false
```

---

## vim.opt_local

`vim.opt_local` is the equivalent of `:setlocal` — sets buffer/window
options on the current buffer/window:

Example:
```lua
vim.opt_local.textwidth = 80
vim.bo.textwidth
```
```expected
80
```

---

## vim.g — global variables

`vim.g` is for `g:` variables, not options. Used by plugins for flags:

Example:
```lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrw
```
```expected
1
```

---

## vim.b — buffer-local variables

`vim.b` is for `b:` variables (distinct from buffer-local OPTIONS):

Example:
```lua
vim.b.my_plugin_state = { ready = true }
vim.b.my_plugin_state.ready
```
```expected
true
```

---

## vim.env — environment variables

Example:
```lua
type(vim.env.HOME)
```
```expected
string
```

---

## Option info

`vim.api.nvim_get_option_info2` returns metadata about an option:

Example:
```lua
local info = vim.api.nvim_get_option_info2("number", {})
info.scope
```
```expected
win
```

Example:
```lua
local info = vim.api.nvim_get_option_info2("expandtab", {})
info.scope
```
```expected
buf
```

---

## Applying many options at once

A common config pattern:

Example:
```lua
local options = {
  expandtab = true,
  tabstop = 2,
  shiftwidth = 2,
  number = true,
}
for k, v in pairs(options) do
  vim.opt[k] = v
end
vim.opt.shiftwidth:get()
```
```expected
2
```

---

# Exercises

---

### Exercise 1

Set tabstop to 4 and shiftwidth to 4. Return shiftwidth.
> Tip: vim.opt or vim.o.

```lua
-- your code here
```
```expected
4
```

---

### Exercise 2

Create a scratch buffer, set its filetype to "python" using vim.bo[buf].
Return the filetype.
> Tip: vim.api.nvim_create_buf(false, true) then vim.bo[buf].filetype.

```lua
-- your code here
```
```expected
python
```

---

### Exercise 3

Check the scope of the "wrap" option using nvim_get_option_info2.
Return the scope string.
> Tip: info.scope will be "win".

```lua
-- your code here
```
```expected
win
```

---

### Exercise 4

Set a buffer-local variable `vim.b.my_counter = 0`, increment it 3 times,
return its final value.
> Tip: vim.b.my_counter = vim.b.my_counter + 1.

```lua
-- your code here
```
```expected
3
```

---

### Exercise 5 — Challenge

Write a `set_ft_options(ft, opts)` function that, given a filetype and
an options table, creates a FileType autocommand that applies those options.
Call it for "lua" with { tabstop=2, expandtab=true }.
Return the number of autocmds registered.
> Tip: nvim_create_augroup + nvim_create_autocmd with FileType pattern.

```lua
-- your code here
```
```expected
1
```
