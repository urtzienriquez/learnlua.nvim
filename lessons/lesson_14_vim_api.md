# Lesson 14: The vim.* Namespace

Neovim exposes its entire API through the `vim` global. This namespace
is the bridge between your Lua code and Neovim's internals.
Understanding its structure is foundational for all plugin development.

---

## The vim namespace structure

| Namespace | Purpose |
|-----------|---------|
| `vim.api` | Raw C API (nvim_*) |
| `vim.fn` | Vimscript functions |
| `vim.opt` | Options (modern) |
| `vim.o/bo/wo` | Options (direct) |
| `vim.g/b/w/t` | Variables |
| `vim.env` | Environment variables |
| `vim.lsp` | LSP client |
| `vim.diagnostic` | Diagnostics |
| `vim.treesitter` | Treesitter |
| `vim.keymap` | Keymaps |
| `vim.uv` | libuv bindings |

Example:
```lua
type(vim.api)
```
```expected
table
```

---

## vim.inspect

The most-used debugging tool. Converts any Lua value to a readable string:

Example:
```lua
vim.inspect({ 1, 2, 3 })
```
```expected
{ 1, 2, 3 }
```

Example:
```lua
vim.inspect({ name = "lua", version = 5 })
```
```expected
{
  name = "lua",
  version = 5
}
```

---

## vim.fn — Vimscript functions

All of Vimscript's built-in functions are available under `vim.fn`:

Example:
```lua
type(vim.fn.getcwd())
```
```expected
string
```

Example:
```lua
vim.fn.toupper("hello")
```
```expected
HELLO
```

Example:
```lua
vim.fn.has("nvim")
```
```expected
1
```

---

## vim.api.nvim_get_current_buf

Returns the handle of the current buffer as a number:

Example:
```lua
type(vim.api.nvim_get_current_buf())
```
```expected
number
```

---

## vim.api.nvim_get_current_win

Returns the handle of the current window:

Example:
```lua
type(vim.api.nvim_get_current_win())
```
```expected
number
```

---

## vim.api.nvim_get_mode

Returns a table with `mode` and `blocking` fields:

Example:
```lua
vim.api.nvim_get_mode().mode
```
```expected
n
```

---

## vim.bo and vim.wo

`vim.bo` reads/writes buffer-local options for the current buffer.
`vim.wo` reads/writes window-local options:

Example:
```lua
type(vim.bo.filetype)
```
```expected
string
```

Example:
```lua
type(vim.wo.number)
```
```expected
boolean
```

---

## vim.g — global variables

Maps to Vimscript's `g:` namespace:

Example:
```lua
vim.g.my_test_var = "hello"
vim.g.my_test_var
```
```expected
hello
```

---

## vim.b — buffer variables

Maps to `b:`:

Example:
```lua
vim.b.my_buf_var = 42
vim.b.my_buf_var
```
```expected
42
```

---

## vim.uv — libuv

`vim.uv` (formerly `vim.loop`) exposes libuv for async work and system calls:

Example:
```lua
type(vim.uv.cwd())
```
```expected
string
```

Example:
```lua
vim.uv.os_getenv("HOME") ~= nil
```
```expected
true
```

---

## vim.tbl_* utility functions

Neovim provides useful table utilities beyond the standard library:

Example:
```lua
vim.tbl_contains({1, 2, 3, 4}, 3)
```
```expected
true
```

Example:
```lua
local evens = vim.tbl_filter(function(v) return v % 2 == 0 end, {1,2,3,4,5,6})
table.concat(evens, ",")
```
```expected
2,4,6
```

Example:
```lua
local doubled = vim.tbl_map(function(v) return v * 2 end, {1,2,3})
table.concat(doubled, ",")
```
```expected
2,4,6
```

---

## vim.deepcopy

Creates a fully independent deep copy of a table:

Example:
```lua
local orig = { nested = { value = 10 } }
local copy = vim.deepcopy(orig)
copy.nested.value = 99
orig.nested.value
```
```expected
10
```

---

## vim.tbl_deep_extend

Recursively merges tables. "force" means later tables win:

Example:
```lua
local a = { x = 1, sub = { y = 2, z = 3 } }
local b = { sub = { y = 99 } }
local merged = vim.tbl_deep_extend("force", a, b)
merged.sub.z   -- preserved from a
```
```expected
3
```

---

# Exercises

---

### Exercise 1

Use vim.inspect to return a readable version of `{ a=1, b=2 }`.
Check that the result is a string.
> Tip: type(vim.inspect({...})).

```lua
-- your code here
```
```expected
string
```

---

### Exercise 2

Get the current working directory using vim.fn.getcwd().
Return its type.
> Tip: type() of the result.

```lua
-- your code here
```
```expected
string
```

---

### Exercise 3

Use vim.tbl_deep_extend to merge `{a=1, b={x=10}}` and `{b={x=99, y=20}}`.
Return b.x from the merged result.
> Tip: "force" means second table wins on conflict.

```lua
-- your code here
```
```expected
99
```

---

### Exercise 4

Use vim.tbl_filter to keep only values > 5 from {2, 4, 6, 8, 10}.
Return their sum.
> Tip: filter, then sum with a for loop.

```lua
-- your code here
```
```expected
24
```

---

### Exercise 5

Create a scratch buffer, set its filetype to "lua" using vim.bo[buf].
Return the filetype to confirm.
> Tip: vim.api.nvim_create_buf(false, true) makes a scratch buffer.

```lua
-- your code here
```
```expected
lua
```

---

### Exercise 6 — Challenge

Use vim.inspect on a nested table `{users={{name="alice"},{name="bob"}}}`.
Return whether the result string contains "alice".
> Tip: use string.find on the inspect output.

```lua
-- your code here
```
```expected
true
```
