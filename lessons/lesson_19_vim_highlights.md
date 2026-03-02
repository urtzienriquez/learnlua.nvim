# Lesson 19: Highlights and Extmarks

Neovim's highlight and extmark APIs give plugins precise control over
how text looks. The system has two layers:

1. **Highlight groups** — named colour/style definitions
2. **Extmarks** — anchored positions in a buffer that carry decorations

Extmarks move with the text as it is edited — they track logical positions,
not line numbers.

---

## Highlight groups

A highlight group is a named set of display attributes.
`nvim_set_hl(ns_id, name, opts)` creates or modifies one.
Namespace 0 is global (affects all contexts):

Example:
```lua
vim.api.nvim_set_hl(0, "MyPlugin_Error", {
  fg = "#ff5555",
  bold = true,
  underline = true,
})
local hl = vim.api.nvim_get_hl(0, { name = "MyPlugin_Error" })
hl.bold
```
```expected
true
```

---

## Highlight attribute fields

| Field | Type | Meaning |
|-------|------|---------|
| `fg` | `"#rrggbb"` or int | foreground colour |
| `bg` | `"#rrggbb"` or int | background colour |
| `sp` | `"#rrggbb"` or int | special colour (underline) |
| `bold` | bool | bold text |
| `italic` | bool | italic text |
| `underline` | bool | underline |
| `undercurl` | bool | wavy underline |
| `strikethrough` | bool | strikethrough |
| `reverse` | bool | swap fg/bg |
| `link` | string | inherit from another group |

---

## Linking highlight groups

`link` makes one group inherit another's attributes:

Example:
```lua
vim.api.nvim_set_hl(0, "MyWarning", { link = "DiagnosticWarn" })
local hl = vim.api.nvim_get_hl(0, { name = "MyWarning" })
hl.link
```
```expected
DiagnosticWarn
```

---

## Namespaces

Namespaces isolate extmarks and highlight decorations so plugins don't
clobber each other. Create one per plugin or per feature:

Example:
```lua
local ns = vim.api.nvim_create_namespace("myplugin.hints")
type(ns)
```
```expected
number
```

---

## nvim_buf_add_highlight (legacy)

The older API — adds a highlight to a range. Still widely used:

`nvim_buf_add_highlight(buf, ns_id, hl_group, line, col_start, col_end)`
- `col_end = -1` means end of line
- Returns an extmark id

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"hello world"})
local ns = vim.api.nvim_create_namespace("test_add_hl")
local id = vim.api.nvim_buf_add_highlight(buf, ns, "Comment", 0, 0, 5)
id >= 0
```
```expected
true
```

---

## nvim_buf_set_extmark — the full API

`nvim_buf_set_extmark(buf, ns, row, col, opts)` is more powerful:
it can move with text, carry virtual text, sign text, and line decorations.

Key options:

| Option | Meaning |
|--------|---------|
| `hl_group` | highlight group for the range |
| `end_row`, `end_col` | extent of the range |
| `virt_text` | `{{text, hl_group}, ...}` after the line |
| `virt_text_pos` | `"eol"`, `"overlay"`, `"right_align"` |
| `virt_lines` | `{{{text, hl}, ...}, ...}` full virtual lines |
| `virt_lines_above` | place virt_lines above the marked line |
| `sign_text` | text in the sign column |
| `sign_hl_group` | highlight for sign_text |
| `number_hl_group` | highlight for the line number |
| `line_hl_group` | whole-line highlight |
| `priority` | rendering priority |
| `right_gravity` | whether mark moves right on insert |

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"function main()"})
local ns = vim.api.nvim_create_namespace("em_hl")
local id = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
  hl_group = "Keyword",
  end_col = 8,  -- highlight "function"
})
id > 0
```
```expected
true
```

---

## Virtual text (end of line)

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"local x = 1"})
local ns = vim.api.nvim_create_namespace("em_virt")
vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
  virt_text = {
    { "  ← number", "Comment" },
  },
  virt_text_pos = "eol",
})
-- Retrieve the extmark and confirm it has virt_text
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true })
marks[1][4].virt_text ~= nil
```
```expected
true
```

---

## Virtual lines

`virt_lines` inserts entire phantom lines above or below a line:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"real line"})
local ns = vim.api.nvim_create_namespace("em_vlines")
local id = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
  virt_lines = {
    { {"  ✓ ok", "DiagnosticOk"} },
    { {"  ← comment", "Comment"} },
  },
  virt_lines_above = false,
})
id > 0
```
```expected
true
```

---

## Retrieving extmarks

`nvim_buf_get_extmarks(buf, ns, start, end, opts)`:
- `start` and `end` are `{row, col}` or `0` / `-1`
- `details = true` returns the opts table alongside position info

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"line a", "line b", "line c"})
local ns = vim.api.nvim_create_namespace("em_get")
for i = 0, 2 do
  vim.api.nvim_buf_set_extmark(buf, ns, i, 0, {})
end
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
#marks
```
```expected
3
```

---

## Updating an extmark

Pass an existing `id` to `nvim_buf_set_extmark` to move or update it:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"a","b","c"})
local ns = vim.api.nvim_create_namespace("em_update")
local id = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {})
-- Move to row 2
vim.api.nvim_buf_set_extmark(buf, ns, 2, 0, { id = id })
local marks = vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
marks[1][2]   -- row of the (now moved) mark
```
```expected
2
```

---

## Clearing extmarks

`nvim_buf_clear_namespace(buf, ns, line_start, line_end)`:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"x","y"})
local ns = vim.api.nvim_create_namespace("em_clear")
vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {})
vim.api.nvim_buf_set_extmark(buf, ns, 1, 0, {})
vim.api.nvim_buf_clear_namespace(buf, ns, 0, -1)
#vim.api.nvim_buf_get_extmarks(buf, ns, 0, -1, {})
```
```expected
0
```

---

## Sign column text

Use `sign_text` to show icons in the sign column:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"error here"})
local ns = vim.api.nvim_create_namespace("em_sign")
local id = vim.api.nvim_buf_set_extmark(buf, ns, 0, 0, {
  sign_text = "E>",
  sign_hl_group = "DiagnosticError",
})
id > 0
```
```expected
true
```

---

# Exercises

---

### Exercise 1

Create a namespace "ex1ns" and verify it returns a number.
> Tip: type(vim.api.nvim_create_namespace("ex1ns")).

```lua
-- your code here
```
```expected
number
```

---

### Exercise 2

Define a highlight group "ExBold" with bold = true.
Read it back and confirm bold is true.
> Tip: nvim_set_hl then nvim_get_hl.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 3

Create a buffer with one line, add an extmark with virt_text "← hint".
Retrieve all extmarks with details = true and return the count.
> Tip: nvim_buf_get_extmarks(buf, ns, 0, -1, { details = true }).

```lua
-- your code here
```
```expected
1
```

---

### Exercise 4

Add 4 extmarks to different lines in a buffer. Clear the namespace.
Return the count of remaining extmarks.
> Tip: nvim_buf_clear_namespace(buf, ns, 0, -1).

```lua
-- your code here
```
```expected
0
```

---

### Exercise 5

Create an extmark at row 0, then update it to row 2 by passing `id`
to a second nvim_buf_set_extmark call. Confirm its new row is 2.
> Tip: marks[1][2] is the row in the get_extmarks result.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 6 — Challenge

Write a function `highlight_pattern(buf, ns, pattern, hl_group)` that
finds all matches of a Lua pattern in a buffer and adds an extmark
highlight for each match.
Test on a buffer with "foo bar foo" — highlight "foo" and return the mark count.
> Tip: get lines, string.find each in a loop, set extmarks with end_col.

```lua
-- your code here
```
```expected
2
```
