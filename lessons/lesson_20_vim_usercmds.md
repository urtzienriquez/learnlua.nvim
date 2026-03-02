# Lesson 20: User Commands

User commands let plugins expose functionality through the Neovim command
line — `:MyCommand args` — just like built-in commands.

The Neovim API documentation says: "User commands are commands defined
by the user or a plugin. They must start with an uppercase letter."

---

## nvim_create_user_command

`vim.api.nvim_create_user_command(name, command, opts)`:
- `name` — must start with uppercase
- `command` — string (executed as Ex command) or Lua function
- `opts` — controls argument handling, range, completion, etc.

Example:
```lua
vim.api.nvim_create_user_command("Ping", function()
end, {})
local cmds = vim.api.nvim_get_commands({})
cmds["Ping"] ~= nil
```
```expected
true
```

---

## The callback opts table

When `command` is a function, it receives a table with:

| Field | Type | Meaning |
|-------|------|---------|
| `name` | string | command name |
| `args` | string | raw argument string |
| `fargs` | table | arguments split on spaces |
| `bang` | bool | whether `!` was appended |
| `line1` | int | start line of range |
| `line2` | int | end line of range |
| `range` | int | 0, 1, or 2 (number of range args) |
| `count` | int | count supplied |
| `reg` | string | optional register |
| `mods` | string | command modifiers (e.g. "silent") |
| `smods` | table | structured modifiers |

---

## nargs — controlling argument count

| `nargs` | Accepted |
|---------|---------|
| `"0"` | no args (default) |
| `"1"` | exactly one |
| `"?"` | zero or one |
| `"*"` | zero or more |
| `"+"` | one or more |

Example:
```lua
local received = ""
vim.api.nvim_create_user_command("EchoTest", function(opts)
  received = opts.args
end, { nargs = "?" })
vim.cmd("EchoTest hello")
received
```
```expected
hello
```

---

## fargs — split argument list

`opts.fargs` is the argument string split by whitespace:

Example:
```lua
local got = {}
vim.api.nvim_create_user_command("MultiArg", function(opts)
  got = opts.fargs
end, { nargs = "*" })
vim.cmd("MultiArg one two three")
#got
```
```expected
3
```

---

## bang — the ! suffix

`bang = true` allows the command to be called with `!`:

Example:
```lua
local banged = false
vim.api.nvim_create_user_command("BangTest", function(opts)
  banged = opts.bang
end, { bang = true })
vim.cmd("BangTest!")
banged
```
```expected
true
```

---

## range — line ranges

`range = true` (or `range = "%"`, `range = "N"`) allows `:'<,'>Cmd`:

Example:
```lua
local r1, r2 = 0, 0
vim.api.nvim_create_user_command("RangeCmd", function(opts)
  r1 = opts.line1
  r2 = opts.line2
end, { range = true })
type(vim.api.nvim_create_user_command)
```
```expected
function
```

---

## complete — tab completion

`complete` specifies what completions are offered.
Built-in values: `"file"`, `"dir"`, `"buffer"`, `"command"`, `"help"`, etc.
Or a Lua function:

Example:
```lua
vim.api.nvim_create_user_command("SetTheme", function(opts)
end, {
  nargs = 1,
  complete = function(arg, line, pos)
    local themes = { "dark", "light", "solarized", "nord" }
    return vim.tbl_filter(function(t)
      return t:sub(1, #arg) == arg
    end, themes)
  end,
})
local cmds = vim.api.nvim_get_commands({})
cmds["SetTheme"] ~= nil
```
```expected
true
```

---

## Buffer-local commands

`nvim_buf_create_user_command(buf, name, fn, opts)` scopes a command
to a specific buffer — automatically deleted when the buffer closes:

Example:
```lua
local buf = vim.api.nvim_get_current_buf()
vim.api.nvim_buf_create_user_command(buf, "BufCmd", function() end, {})
local cmds = vim.api.nvim_buf_get_commands(buf, {})
cmds["BufCmd"] ~= nil
```
```expected
true
```

---

## Deleting commands

`nvim_del_user_command(name)` removes a global command.
`nvim_buf_del_user_command(buf, name)` removes a buffer-local one:

Example:
```lua
vim.api.nvim_create_user_command("TempDel", function() end, {})
vim.api.nvim_del_user_command("TempDel")
vim.api.nvim_get_commands({})["TempDel"] == nil
```
```expected
true
```

---

## vim.cmd — calling commands from Lua

`vim.cmd("CmdName args")` — string form.
`vim.cmd.CmdName(args)` — modern dot-notation form:

Example:
```lua
local result = ""
vim.api.nvim_create_user_command("Echo2", function(o) result = o.args end, { nargs = "?" })
vim.cmd.Echo2("world")
result
```
```expected
world
```

---

## Building a plugin command API

A common pattern — dispatch subcommands:

Example:
```lua
local function cmd_open()  return "opened"  end
local function cmd_close() return "closed"  end

local subcommands = { open = cmd_open, close = cmd_close }

vim.api.nvim_create_user_command("MyTool", function(opts)
  local sub = opts.fargs[1]
  if subcommands[sub] then
    return subcommands[sub]()
  end
end, {
  nargs = "+",
  complete = function() return vim.tbl_keys(subcommands) end,
})

-- Test dispatch
local r = cmd_open()
r
```
```expected
opened
```

---

# Exercises

---

### Exercise 1

Create a command "Greet" with nargs="1" that stores "Hello, <arg>!"
in a variable. Call it with "Lua". Return the variable.
> Tip: result = "Hello, " .. opts.args .. "!".

```lua
local result = ""
-- your code here
```
```expected
Hello, Lua!
```

---

### Exercise 2

Create a command "Add" with nargs="+" that sums its numeric arguments.
Call it with "3 4 5". Return the total.
> Tip: iterate opts.fargs with tonumber().

```lua
local total = 0
-- your code here
```
```expected
12
```

---

### Exercise 3

Create a "Force" command with bang=true. Call it with !.
Return the opts.bang value (should be true).
> Tip: store opts.bang in an outer variable.

```lua
local banged = false
-- your code here
```
```expected
true
```

---

### Exercise 4

Create a buffer-local command "BufGreet". Verify it appears in
nvim_buf_get_commands but NOT in nvim_get_commands (global).
Return true if found in buffer, false in global.
> Tip: nvim_buf_create_user_command + check both maps.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 5 — Challenge

Build a dispatch command "Plugin" that accepts subcommands "start", "stop",
"status". Each sets a `state` variable. Call "Plugin status".
Return the state.
> Tip: subcommands[opts.fargs[1]]() dispatch pattern.

```lua
local state = ""
-- your code here
```
```expected
status
```
