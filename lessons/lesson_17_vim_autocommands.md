# Lesson 17: Autocommands

Autocommands run Lua callbacks automatically in response to Neovim events.
They are the backbone of plugin behaviour — triggered by file opens, saves,
cursor movement, mode changes, and dozens of other events.

The Neovim documentation says: *"Autocommands are a way to tell Vim to
execute commands automatically when reading or writing a file, or when
entering or leaving a buffer or window."*

---

## 1. nvim_create_autocmd

`vim.api.nvim_create_autocmd(events, opts)` creates one or more autocommands:

| Key | Type | Description |
|-----|------|-------------|
| `events` | string or list | Event name(s) |
| `group` | string or number | Augroup to add to |
| `pattern` | string or list | File pattern(s) to match |
| `buffer` | number | Buffer-local (exclusive with pattern) |
| `callback` | function | Lua callback |
| `command` | string | Vimscript command (alternative to callback) |
| `once` | bool | Delete after first trigger |
| `nested` | bool | Allow nested autocommands |
| `desc` | string | Human-readable description |

Returns: the integer ID of the created autocommand.

Example:
```lua
local id = vim.api.nvim_create_autocmd("BufEnter", {
  callback = function() end,
  desc = "test autocmd",
})
type(id)
```
```expected
number
```

---

## 2. Autocommand Groups

Groups (`augroups`) let you manage sets of related autocommands.
The critical pattern is `{ clear = true }` when creating/recreating a group —
this removes any existing autocommands in that group, preventing duplicates
when your config is re-sourced.

Example:
```lua
local g = vim.api.nvim_create_augroup("MyPlugin", { clear = true })
type(g)
```
```expected
number
```

---

Example:
```lua
-- clear = true removes existing cmds; prevents accumulation on re-source
local g = vim.api.nvim_create_augroup("TestGroup", { clear = true })
vim.api.nvim_create_autocmd("BufEnter", { group = g, callback = function() end })
vim.api.nvim_create_autocmd("BufLeave", { group = g, callback = function() end })

-- Re-create with clear=true wipes both:
vim.api.nvim_create_augroup("TestGroup", { clear = true })
local cmds = vim.api.nvim_get_autocmds({ group = g })
#cmds
```
```expected
0
```

---

## 3. Common Events

| Event | Triggered when |
|-------|---------------|
| `BufEnter` | entering a buffer |
| `BufLeave` | leaving a buffer |
| `BufWritePre` | before writing a file |
| `BufWritePost` | after writing a file |
| `BufReadPost` | after reading a file into a buffer |
| `BufNewFile` | creating a new file |
| `FileType` | filetype is detected/changed |
| `InsertEnter` | entering Insert mode |
| `InsertLeave` | leaving Insert mode |
| `CursorMoved` | cursor moved in Normal mode |
| `CursorMovedI` | cursor moved in Insert mode |
| `WinEnter` | entering a window |
| `WinLeave` | leaving a window |
| `VimEnter` | Vim has fully started |
| `VimLeave` | Vim is about to exit |
| `User` | custom user events (with pattern) |
| `TextChanged` | text changed in Normal mode |
| `TextChangedI` | text changed in Insert mode |
| `LspAttach` | LSP client attached to buffer |

Example:
```lua
local g = vim.api.nvim_create_augroup("Events", { clear = true })
vim.api.nvim_create_autocmd({ "BufEnter", "BufLeave" }, {
  group = g,
  callback = function() end,
})
local cmds = vim.api.nvim_get_autocmds({ group = g })
#cmds
```
```expected
2
```

---

## 4. Pattern Matching

`pattern` limits which files trigger the autocommand. Supports glob patterns:

Example:
```lua
local g = vim.api.nvim_create_augroup("PatTest", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = { "*.lua", "*.vim" },
  group   = g,
  callback = function() end,
})
local cmds = vim.api.nvim_get_autocmds({ group = g })
#cmds
```
```expected
1
```

---

## 5. FileType Autocommands

`FileType` is a special event for language detection. Use it to configure
buffer-local settings per language:

Example:
```lua
local g = vim.api.nvim_create_augroup("FtConfig", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern  = "lua",
  group    = g,
  callback = function()
    vim.opt_local.tabstop    = 2
    vim.opt_local.shiftwidth = 2
  end,
})
local cmds = vim.api.nvim_get_autocmds({ group = g, event = "FileType" })
#cmds
```
```expected
1
```

---

## 6. Buffer-Local Autocommands

`buffer = bufnr` limits the autocommand to one buffer.
These are automatically cleaned up when the buffer is deleted:

Example:
```lua
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_create_autocmd("TextChanged", {
  buffer   = buf,
  callback = function() end,
  desc     = "buffer-local autocmd",
})
local cmds = vim.api.nvim_get_autocmds({ event = "TextChanged", buffer = buf })
#cmds >= 1
```
```expected
true
```

---

## 7. once — Self-Destructing Autocommands

`once = true` deletes the autocommand after it fires the first time.
Ideal for one-time initialization after VimEnter, or guarding first-run logic:

Example:
```lua
local g   = vim.api.nvim_create_augroup("OnceTest", { clear = true })
local fired = 0
vim.api.nvim_create_autocmd("User", {
  pattern  = "MyOnceEvent",
  group    = g,
  once     = true,
  callback = function() fired = fired + 1 end,
})
vim.api.nvim_exec_autocmds("User", { pattern = "MyOnceEvent" })
vim.api.nvim_exec_autocmds("User", { pattern = "MyOnceEvent" })  -- should not fire
fired
```
```expected
1
```

---

## 8. nvim_exec_autocmds — Trigger Manually

You can fire autocommands from Lua using `nvim_exec_autocmds`:

Example:
```lua
local g = vim.api.nvim_create_augroup("ExecTest", { clear = true })
local log = {}
vim.api.nvim_create_autocmd("User", {
  pattern  = "MyEvent",
  group    = g,
  callback = function(ev)
    table.insert(log, ev.match)
  end,
})
vim.api.nvim_exec_autocmds("User", { pattern = "MyEvent" })
vim.api.nvim_exec_autocmds("User", { pattern = "MyEvent" })
#log
```
```expected
2
```

---

## 9. The event callback argument

The callback receives a table `ev` with information about the event:

| Field | Description |
|-------|-------------|
| `ev.id` | autocommand ID |
| `ev.event` | event name string |
| `ev.group` | augroup ID (may be nil) |
| `ev.match` | matched string (pattern or buffer name) |
| `ev.buf` | buffer number |
| `ev.file` | file name |
| `ev.data` | extra data passed by exec_autocmds |

Example:
```lua
local g = vim.api.nvim_create_augroup("EvArgTest", { clear = true })
local received = {}
vim.api.nvim_create_autocmd("User", {
  pattern  = "TestArg",
  group    = g,
  callback = function(ev)
    received.event = ev.event
    received.match = ev.match
  end,
})
vim.api.nvim_exec_autocmds("User", { pattern = "TestArg" })
received.event .. "/" .. received.match
```
```expected
User/TestArg
```

---

## 10. nvim_del_autocmd

Delete a specific autocommand by its numeric ID:

Example:
```lua
local id = vim.api.nvim_create_autocmd("CursorMoved", {
  callback = function() end,
})
vim.api.nvim_del_autocmd(id)
-- Trying to delete it again should fail:
local ok = pcall(vim.api.nvim_del_autocmd, id)
ok
```
```expected
false
```

---

## 11. nvim_get_autocmds — Querying

`vim.api.nvim_get_autocmds(opts)` returns a list of matching autocommands.
Filter by `event`, `group`, `buffer`, or `pattern`:

Example:
```lua
local g = vim.api.nvim_create_augroup("QueryTest", { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", { group = g, callback = function() end })
vim.api.nvim_create_autocmd("BufWritePost", { group = g, callback = function() end })
vim.api.nvim_create_autocmd("BufReadPost",  { group = g, callback = function() end })

local write_cmds = vim.api.nvim_get_autocmds({
  group = g,
  event = { "BufWritePre", "BufWritePost" }
})
#write_cmds
```
```expected
2
```

---

---

# Exercises

---

### Exercise 1 — Create and count

Create an augroup "Ex1" with clear=true, add 3 BufEnter autocommands.
Return the count.
> Tip: nvim_get_autocmds({ group = g }) after adding.

```lua
-- your code here
```
```expected
3
```

---

### Exercise 2 — Clear on re-create

Create a group, add 2 autocmds, then re-create with clear=true.
Return the count after clearing.
> Tip: re-creating with clear=true removes all existing commands.

```lua
-- your code here
```
```expected
0
```

---

### Exercise 3 — once fires exactly once

Create a `once = true` User autocmd. Fire it 3 times.
Return how many times the callback actually ran.
> Tip: once=true deletes the autocmd after first fire.

```lua
-- your code here
```
```expected
1
```

---

### Exercise 4 — callback event data

Create a User autocmd and fire it. Capture ev.event in the callback.
Return the captured event name.
> Tip: ev.event is the string "User".

```lua
-- your code here
```
```expected
User
```

---

### Exercise 5 — filter by event

Create one BufWritePre and two BufReadPost autocmds in a group.
Query only BufReadPost ones. Return the count.
> Tip: nvim_get_autocmds({ group = g, event = "BufReadPost" }).

```lua
-- your code here
```
```expected
2
```

---

### Exercise 6 — data passing

Pass custom data through exec_autocmds.
In the callback, read ev.data.message. Return that string.
> Tip: nvim_exec_autocmds("User", { pattern="X", data={ message="hi" } }).

```lua
-- your code here
```
```expected
hi
```

---

### Exercise 7 — Challenge: autocmd wrapper

Write a function `on_filetype(ft, fn)` that registers a FileType autocmd
for `ft` in a group named "on_ft_" .. ft.
Call it for "python", then return the count of autocmds in the resulting group.
> Tip: create the augroup then create_autocmd with pattern=ft.

```lua
-- your code here
```
```expected
1
```
