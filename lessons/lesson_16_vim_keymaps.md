# Lesson 16: Keymaps and Key Bindings

Neovim's keymap API lets you register, query, and remove key mappings
entirely in Lua. The modern API (`vim.keymap.set`) supersedes the old
`vim.api.nvim_set_keymap` by handling noremap automatically and accepting
Lua functions directly.

---

## 1. vim.keymap.set

`vim.keymap.set(mode, lhs, rhs, opts)` is the recommended entry point.

| Parameter | Type | Description |
|-----------|------|-------------|
| `mode` | string or table | Vim mode(s) |
| `lhs` | string | Left-hand side: the key sequence |
| `rhs` | string or function | Right-hand side: what to run |
| `opts` | table | Options (see below) |

Example:
```lua
vim.keymap.set("n", "<leader>h", function()
  return "hello"
end, { desc = "Say hello" })
-- verify it was registered
local maps = vim.api.nvim_get_keymap("n")
local found = false
for _, m in ipairs(maps) do
  if m.desc == "Say hello" then found = true end
end
found
```
```expected
true
```

---

## 2. Mode Strings

| Mode | Vim name | Description |
|------|----------|-------------|
| `"n"` | Normal | Normal mode |
| `"i"` | Insert | Insert mode |
| `"v"` | Visual+Select | Visual and Select mode |
| `"x"` | Visual | Visual mode only (not Select) |
| `"s"` | Select | Select mode |
| `"o"` | Operator-pending | After an operator like `d` or `y` |
| `"t"` | Terminal | Terminal mode |
| `"c"` | Command | Command-line mode |
| `"l"` | Lang-arg | `i`, `r`, `?`, and more |
| `""` | Normal+Visual+Op | Catch-all (`:map`) |

Example:
```lua
-- Multiple modes at once
vim.keymap.set({ "n", "v" }, "<leader>test", function() end, { desc = "test multi" })
local maps = vim.api.nvim_get_keymap("n")
local found = false
for _, m in ipairs(maps) do
  if m.desc == "test multi" then found = true end
end
found
```
```expected
true
```

---

## 3. Key Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| `noremap` | bool | `true` | Don't expand rhs recursively |
| `silent` | bool | `false` | Don't echo the mapping |
| `expr` | bool | `false` | rhs is an expression; its return value is used |
| `buffer` | bool/number | `false` | Buffer-local mapping |
| `desc` | string | `nil` | Description (shown in which-key, `:map`) |
| `nowait` | bool | `false` | Don't wait for more keys |
| `remap` | bool | `false` | Allow remapping (inverse of noremap) |

Example:
```lua
vim.keymap.set("n", "<leader>q", ":quit<CR>", {
  silent  = true,
  desc    = "Quit Neovim",
})
local maps = vim.api.nvim_get_keymap("n")
local found = false
for _, m in ipairs(maps) do
  if m.desc == "Quit Neovim" then found = true end
end
found
```
```expected
true
```

---

## 4. Buffer-Local Keymaps

`buffer = true` scopes the mapping to the current buffer.
`buffer = bufnr` scopes it to a specific buffer number.
Buffer-local maps take precedence over global maps.

Example:
```lua
local buf = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "<leader>bl", function() end, {
  buffer = buf,
  desc   = "buffer-local test",
})
local maps = vim.api.nvim_buf_get_keymap(buf, "n")
local found = false
for _, m in ipairs(maps) do
  if m.desc == "buffer-local test" then found = true end
end
found
```
```expected
true
```

---

## 5. vim.keymap.del — Removing Keymaps

`vim.keymap.del(mode, lhs, opts)` removes a keymap:

Example:
```lua
vim.keymap.set("n", "<leader>tmp1", function() end, {})
vim.keymap.del("n", "<leader>tmp1")
local maps = vim.api.nvim_get_keymap("n")
local found = false
for _, m in ipairs(maps) do
  if m.lhs == " tmp1" then found = true end
end
found
```
```expected
false
```

---

Example:
```lua
-- Delete buffer-local mapping
local buf = vim.api.nvim_get_current_buf()
vim.keymap.set("n", "<leader>bldel", function() end, { buffer = buf })
vim.keymap.del("n", "<leader>bldel", { buffer = buf })
local maps = vim.api.nvim_buf_get_keymap(buf, "n")
local found = false
for _, m in ipairs(maps) do
  if m.lhs == " bldel" then found = true end
end
found
```
```expected
false
```

---

## 6. Querying Keymaps

`vim.api.nvim_get_keymap(mode)` returns all global keymaps for a mode.
`vim.api.nvim_buf_get_keymap(buf, mode)` returns buffer-local keymaps.

Each entry is a table with fields: `lhs`, `rhs`, `desc`, `noremap`, `silent`, etc.

Example:
```lua
type(vim.api.nvim_get_keymap("n"))
```
```expected
table
```

---

Example:
```lua
-- Find a keymap by desc
vim.keymap.set("n", "<leader>findme", function() end, { desc = "findme-desc" })
local maps = vim.api.nvim_get_keymap("n")
local result = nil
for _, m in ipairs(maps) do
  if m.desc == "findme-desc" then
    result = m.lhs
    break
  end
end
result ~= nil
```
```expected
true
```

---

## 7. expr Mappings

`expr = true` means the rhs is evaluated as an expression and its
return value becomes the keys to execute. Useful for context-sensitive maps:

Example:
```lua
vim.keymap.set("i", "<Tab>", function()
  -- In a real plugin: check for completion popup, etc.
  return "<Tab>"
end, { expr = true, desc = "smart tab" })
type(vim.keymap.set)
```
```expected
function
```

---

## 8. Using <Plug> Mappings

`<Plug>` creates a named internal mapping other mappings can use.
This is a plugin convention that lets users remap plugin actions:

Example:
```lua
-- Plugin defines the action:
vim.keymap.set("n", "<Plug>(MyAction)", function() end, { noremap = false })
-- User can remap it to their preferred key:
-- vim.keymap.set("n", "ga", "<Plug>(MyAction)")
type(vim.keymap.set)
```
```expected
function
```

---

## 9. FileType Keymaps

Register keymaps inside a FileType autocommand so they apply only to
specific filetypes:

Example:
```lua
local g = vim.api.nvim_create_augroup("LuaKeymaps", { clear = true })
vim.api.nvim_create_autocmd("FileType", {
  pattern = "lua",
  group = g,
  callback = function(ev)
    vim.keymap.set("n", "<leader>lr", function() end, {
      buffer = ev.buf,
      desc   = "Run Lua",
    })
  end,
})
local cmds = vim.api.nvim_get_autocmds({ group = g })
#cmds
```
```expected
1
```

---

## 10. Helper: Map Table

A convenient pattern for defining many mappings at once:

Example:
```lua
local function set_maps(maps, global_opts)
  for _, map in ipairs(maps) do
    local mode, lhs, rhs, opts = map[1], map[2], map[3], map[4] or {}
    opts = vim.tbl_extend("force", global_opts or {}, opts)
    vim.keymap.set(mode, lhs, rhs, opts)
  end
end

local buf = vim.api.nvim_get_current_buf()
set_maps({
  { "n", "<leader>t1", function() end, { desc = "test1" } },
  { "n", "<leader>t2", function() end, { desc = "test2" } },
  { "n", "<leader>t3", function() end, { desc = "test3" } },
}, { buffer = buf, silent = true })

local maps = vim.api.nvim_buf_get_keymap(buf, "n")
local count = 0
for _, m in ipairs(maps) do
  if m.desc and m.desc:match("^test%d$") then
    count = count + 1
  end
end
count
```
```expected
3
```

---

---

# Exercises

---

### Exercise 1 — Register and verify

Register a global normal-mode keymap for `<leader>ex1` with desc "ex1-test".
Verify it appears in nvim_get_keymap("n"). Return true if found.
> Tip: search the maps table for m.desc == "ex1-test".

```lua
-- your code here
```
```expected
true
```

---

### Exercise 2 — Buffer-local

Register a buffer-local keymap for the current buffer.
Verify it appears in nvim_buf_get_keymap but NOT in nvim_get_keymap.
Return true if buffer-local is found.
> Tip: use buffer = true in opts.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 3 — Delete

Register then delete a keymap. Return false if it's no longer found.
> Tip: vim.keymap.del(mode, lhs).

```lua
-- your code here
```
```expected
false
```

---

### Exercise 4 — Multi-mode

Register the same keymap in both "n" and "i" modes in a single call.
Check that it appears in both nvim_get_keymap("n") and nvim_get_keymap("i").
Return true if found in both.
> Tip: pass { "n", "i" } as the first argument.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 5 — Count by desc prefix

Register 5 keymaps with desc starting with "myplugin-".
Count how many global normal-mode maps have desc matching "myplugin-.*".
> Tip: m.desc and m.desc:match("^myplugin%-") in the loop.

```lua
-- your code here
```
```expected
5
```

---

### Exercise 6 — Challenge: conditional rhs

Register an expr keymap that returns "<Esc>" if the current line is empty
and "<CR>" otherwise. Verify the mapping has expr=1.
> Tip: `expr = true` in opts; access m.expr in the verification.

```lua
-- your code here
```
```expected
true
```
