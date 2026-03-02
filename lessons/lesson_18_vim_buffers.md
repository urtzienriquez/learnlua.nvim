# Lesson 18: Buffers, Windows, and Tabpages

Neovim's display model has three layers:
- **Buffers** — in-memory text (may or may not be visible)
- **Windows** — viewports that display a buffer
- **Tabpages** — collections of windows

A buffer can be shown in multiple windows simultaneously. A window always
shows exactly one buffer. Understanding this model is essential for writing
plugins that manipulate the editor layout.

The Neovim API documentation says: "A buffer is a file loaded into memory
for editing. Windows are views onto buffers. A tabpage is a collection of
windows." Handles are integers — buffers get buffer handles, windows get
window handles, tabpages get tabpage handles.

---

## Buffers — creating and querying

`nvim_create_buf(listed, scratch)` creates a new buffer:
- `listed = true` → appears in `:ls` buffer list
- `scratch = true` → no file association, won't ask to save

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_is_valid(buf)
```
```expected
true
```

---

## nvim_list_bufs

Returns all buffer handles (including unlisted ones):

Example:
```lua
local bufs = vim.api.nvim_list_bufs()
type(bufs) == "table" and #bufs >= 1
```
```expected
true
```

---

## Buffer content — set_lines / get_lines

`nvim_buf_set_lines(buf, start, end, strict_indexing, lines)`:
- Lines are 0-indexed
- `end = -1` means the last line
- The lines table replaces the range

`nvim_buf_get_lines(buf, start, end, strict_indexing)`:
- Returns a table of strings (without newlines)

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "line one",
  "line two",
  "line three",
})
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
#lines
```
```expected
3
```

---

## Replacing a range of lines

To replace only some lines, set start/end accordingly:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"a","b","c","d","e"})
-- Replace lines 1-3 (0-indexed) with two lines
vim.api.nvim_buf_set_lines(buf, 1, 4, false, {"X", "Y"})
local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
table.concat(lines, ",")
```
```expected
a,X,Y,e
```

---

## nvim_buf_set_text — character-precise editing

Unlike `set_lines`, `nvim_buf_set_text` works at character level:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"hello world"})
-- Replace bytes 6-11 on line 0 with "Lua"
vim.api.nvim_buf_set_text(buf, 0, 6, 0, 11, {"Lua"})
vim.api.nvim_buf_get_lines(buf, 0, -1, false)[1]
```
```expected
hello Lua
```

---

## Buffer name

`nvim_buf_set_name` sets the display name. For scratch buffers this
is just cosmetic (no file on disk):

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_name(buf, "my-scratch-buffer")
local name = vim.api.nvim_buf_get_name(buf)
vim.fn.fnamemodify(name, ":t")
```
```expected
my-scratch-buffer
```

---

## Buffer options via vim.bo[buf]

Set buffer-local options on any buffer by handle:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.bo[buf].filetype = "lua"
vim.bo[buf].modifiable = false
vim.bo[buf].modifiable
```
```expected
false
```

---

## Buffer variables via vim.b[buf]

`vim.b[buf]` accesses `b:` variables for a specific buffer:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.b[buf].my_flag = "active"
vim.b[buf].my_flag
```
```expected
active
```

---

## Deleting a buffer

`nvim_buf_delete(buf, opts)`:
- `force = true` abandons unsaved changes

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_delete(buf, { force = true })
vim.api.nvim_buf_is_valid(buf)
```
```expected
false
```

---

## Windows — nvim_list_wins

Returns all window handles:

Example:
```lua
local wins = vim.api.nvim_list_wins()
type(wins) == "table" and #wins >= 1
```
```expected
true
```

---

## Window-buffer relationship

`nvim_win_get_buf(win)` and `nvim_win_set_buf(win, buf)`:

Example:
```lua
local win = vim.api.nvim_get_current_win()
local buf = vim.api.nvim_win_get_buf(win)
vim.api.nvim_buf_is_valid(buf)
```
```expected
true
```

---

## Cursor position

`nvim_win_get_cursor(win)` → `{row, col}` (1-indexed row, 0-indexed col)
`nvim_win_set_cursor(win, {row, col})` moves the cursor:

Example:
```lua
local win = vim.api.nvim_get_current_win()
local pos = vim.api.nvim_win_get_cursor(win)
type(pos) == "table" and #pos == 2
```
```expected
true
```

---

## Window options via vim.wo[win]

Example:
```lua
local win = vim.api.nvim_get_current_win()
vim.wo[win].number = false
vim.wo[win].number
```
```expected
false
```

---

## Floating windows

Floating windows overlay the editor. `nvim_open_win` with `relative` set:

| `relative` value | Anchor point |
|-----------------|--------------|
| `"editor"` | whole editor |
| `"win"` | a specific window |
| `"cursor"` | cursor position |
| `"mouse"` | mouse position |

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"  Hello from float!  "})
local win = vim.api.nvim_open_win(buf, false, {
  relative = "editor",
  row = 2, col = 4,
  width = 24, height = 3,
  style = "minimal",
  border = "rounded",
})
vim.api.nvim_win_is_valid(win)
```
```expected
true
```

---

## Closing a window

`nvim_win_close(win, force)`:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buf, false, {
  relative = "editor", row = 1, col = 1,
  width = 10, height = 3, style = "minimal",
})
vim.api.nvim_win_close(win, true)
vim.api.nvim_win_is_valid(win)
```
```expected
false
```

---

## Window configuration

`nvim_win_get_config(win)` returns the window's config.
For floating windows this includes all the `open_win` options:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
local win = vim.api.nvim_open_win(buf, false, {
  relative = "editor", row = 1, col = 1,
  width = 20, height = 5, style = "minimal",
})
local config = vim.api.nvim_win_get_config(win)
config.width
```
```expected
20
```

---

## Tabpages

`nvim_list_tabpages()`, `nvim_get_current_tabpage()`:

Example:
```lua
local tabs = vim.api.nvim_list_tabpages()
type(tabs) == "table" and #tabs >= 1
```
```expected
true
```

---

# Exercises

---

### Exercise 1

Create a scratch buffer, write four lines into it, then read them back.
Return the line count.
> Tip: nvim_buf_set_lines with 4 strings, then #nvim_buf_get_lines(...).

```lua
-- your code here
```
```expected
4
```

---

### Exercise 2

Create a buffer with lines "a","b","c","d","e". Replace lines at index 1–3
(the "b","c","d" section) with a single line "replaced".
Return the resulting lines joined by commas.
> Tip: nvim_buf_set_lines(buf, 1, 4, false, {"replaced"}).

```lua
-- your code here
```
```expected
a,replaced,e
```

---

### Exercise 3

Create a floating window with border = "single" and width = 30.
Read back its config and return the width.
> Tip: nvim_win_get_config(win).width.

```lua
-- your code here
```
```expected
30
```

---

### Exercise 4

Create a buffer, write "hello world" as the first line, then use
nvim_buf_set_text to replace "world" with "Neovim".
Return the new first line.
> Tip: "world" starts at column 6 and ends at column 11 on row 0.

```lua
-- your code here
```
```expected
hello Neovim
```

---

### Exercise 5

Create a buffer, set its filetype to "lua" and a buffer variable
`b:lesson = "buffers"`. Return the value of b:lesson.
> Tip: vim.b[buf].lesson = "buffers" then read it back.

```lua
-- your code here
```
```expected
buffers
```

---

### Exercise 6 — Challenge

Write a function `open_popup(lines)` that creates a floating window with
rounded borders, centred in the editor, showing the given lines.
Return the text of the first line from the buffer backing that window.
> Tip: nvim_open_win with relative="editor"; read back with nvim_buf_get_lines.

```lua
-- your code here
```
```expected
hello popup
```
