# Lesson 21: LSP — Language Server Protocol

Neovim has a built-in LSP client since version 0.5. It implements the
Language Server Protocol, which defines a standard communication layer
between editors and language-specific tools (Go, Rust, Python, Lua, etc.).

The Neovim LSP documentation says: "Neovim supports the Language Server
Protocol (LSP), which means it acts as a client to LSP servers and includes
a Lua framework to build enhanced LSP tools."

---

## Architecture overview

```
Neovim (LSP client)  ←→  Language Server (e.g. lua-language-server)
      ↕                          ↕
   vim.lsp.*              textDocument/hover
   vim.lsp.buf.*          textDocument/definition
   vim.diagnostic.*       publishDiagnostics
```

---

## vim.lsp.get_clients

Returns all active LSP clients. Filter by buffer, name, method, etc:

Example:
```lua
local clients = vim.lsp.get_clients()
type(clients)
```
```expected
table
```

---

## vim.lsp.start

`vim.lsp.start(config)` starts an LSP server and attaches to the current buffer.
Returns the client id (integer) or nil if already running:

Example:
```lua
-- Just verify the function exists
type(vim.lsp.start)
```
```expected
function
```

---

## Checking for attached clients

Example:
```lua
local buf = vim.api.nvim_get_current_buf()
local clients = vim.lsp.get_clients({ bufnr = buf })
type(clients) == "table"
```
```expected
true
```

---

## vim.diagnostic namespace

`vim.diagnostic` manages diagnostics (errors, warnings, hints) independently
of whether an LSP is active. Plugins can create diagnostics programmatically:

Example:
```lua
type(vim.diagnostic)
```
```expected
table
```

---

## Severity levels

| Constant | Value | Meaning |
|----------|-------|---------|
| `vim.diagnostic.severity.ERROR` | 1 | compilation errors |
| `vim.diagnostic.severity.WARN` | 2 | possible issues |
| `vim.diagnostic.severity.INFO` | 3 | informational |
| `vim.diagnostic.severity.HINT` | 4 | suggestions |

Example:
```lua
vim.diagnostic.severity.ERROR
```
```expected
1
```

---

## vim.diagnostic.set

`vim.diagnostic.set(ns, buf, diagnostics, opts)` attaches a list of
diagnostic objects to a buffer. Each diagnostic needs at minimum:
- `lnum` — 0-indexed line number
- `col` — 0-indexed column
- `severity` — one of the severity constants
- `message` — human-readable description

Example:
```lua
local ns = vim.api.nvim_create_namespace("diag_lesson")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"bad code here", "more bad code"})

vim.diagnostic.set(ns, buf, {
  {
    lnum = 0, col = 0,
    severity = vim.diagnostic.severity.ERROR,
    message = "undefined variable",
    source = "my_linter",
  },
  {
    lnum = 1, col = 0,
    severity = vim.diagnostic.severity.WARN,
    message = "unused variable",
    source = "my_linter",
  },
})
#vim.diagnostic.get(buf)
```
```expected
2
```

---

## vim.diagnostic.get

Retrieve diagnostics, optionally filtered:

Example:
```lua
local ns = vim.api.nvim_create_namespace("diag_get_lesson")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"x"})
vim.diagnostic.set(ns, buf, {
  { lnum=0, col=0, severity=vim.diagnostic.severity.ERROR, message="e1" },
  { lnum=0, col=0, severity=vim.diagnostic.severity.WARN,  message="w1" },
  { lnum=0, col=0, severity=vim.diagnostic.severity.INFO,  message="i1" },
})
local errors = vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.ERROR })
#errors
```
```expected
1
```

---

## vim.diagnostic.reset

`vim.diagnostic.reset(ns, buf)` removes all diagnostics from a namespace:

Example:
```lua
local ns = vim.api.nvim_create_namespace("diag_reset_lesson")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"line"})
vim.diagnostic.set(ns, buf, {
  { lnum=0, col=0, severity=vim.diagnostic.severity.ERROR, message="x" }
})
vim.diagnostic.reset(ns, buf)
#vim.diagnostic.get(buf, { namespace = ns })
```
```expected
0
```

---

## vim.diagnostic.config

Controls how diagnostics are displayed globally:

Example:
```lua
vim.diagnostic.config({
  virtual_text = {
    prefix = "●",
    spacing = 4,
  },
  signs = true,
  underline = true,
  update_in_insert = false,
  severity_sort = true,
})
type(vim.diagnostic.config)
```
```expected
function
```

---

## vim.diagnostic.count

Returns counts per severity for a buffer:

Example:
```lua
local ns = vim.api.nvim_create_namespace("diag_count_lesson")
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {"x"})
vim.diagnostic.set(ns, buf, {
  { lnum=0, col=0, severity=vim.diagnostic.severity.ERROR, message="a" },
  { lnum=0, col=0, severity=vim.diagnostic.severity.ERROR, message="b" },
  { lnum=0, col=0, severity=vim.diagnostic.severity.WARN,  message="c" },
})
local counts = vim.diagnostic.count(buf)
counts[vim.diagnostic.severity.ERROR]
```
```expected
2
```

---

## vim.lsp.buf functions

These operate on the buffer's currently-attached LSP clients.
They send requests to the server and handle responses asynchronously:

| Function | LSP method |
|----------|-----------|
| `vim.lsp.buf.hover()` | `textDocument/hover` |
| `vim.lsp.buf.definition()` | `textDocument/definition` |
| `vim.lsp.buf.references()` | `textDocument/references` |
| `vim.lsp.buf.rename(new)` | `textDocument/rename` |
| `vim.lsp.buf.code_action()` | `textDocument/codeAction` |
| `vim.lsp.buf.format(opts)` | `textDocument/formatting` |
| `vim.lsp.buf.signature_help()` | `textDocument/signatureHelp` |

Example:
```lua
type(vim.lsp.buf.hover)
```
```expected
function
```

---

## LspAttach autocommand

The idiomatic way to set up per-buffer LSP keymaps:

Example:
```lua
local g = vim.api.nvim_create_augroup("LspLesson", { clear = true })
vim.api.nvim_create_autocmd("LspAttach", {
  group = g,
  callback = function(ev)
    local buf = ev.buf
    vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = buf })
    vim.keymap.set("n", "K",  vim.lsp.buf.hover,      { buffer = buf })
    vim.keymap.set("n", "gr", vim.lsp.buf.references,  { buffer = buf })
  end,
})
#vim.api.nvim_get_autocmds({ group = g })
```
```expected
1
```

---

# Exercises

---

### Exercise 1

Create a namespace and scratch buffer, set one ERROR diagnostic.
Return the count.
> Tip: vim.diagnostic.set then vim.diagnostic.get.

```lua
-- your code here
```
```expected
1
```

---

### Exercise 2

Set diagnostics of all four severities. Return the count of only WARNs.
> Tip: vim.diagnostic.get(buf, { severity = vim.diagnostic.severity.WARN }).

```lua
-- your code here
```
```expected
1
```

---

### Exercise 3

Set 3 diagnostics, reset the namespace, return remaining count.
> Tip: vim.diagnostic.reset(ns, buf).

```lua
-- your code here
```
```expected
0
```

---

### Exercise 4

Use vim.diagnostic.count to count diagnostics by severity.
Set 3 ERRORs and 2 WARNs. Return the ERROR count.
> Tip: vim.diagnostic.count(buf)[vim.diagnostic.severity.ERROR].

```lua
-- your code here
```
```expected
3
```

---

### Exercise 5 — Challenge

Write `count_above(buf, min_severity)` that counts diagnostics at or above
(numerically ≤) a given severity. Set ERROR(1), WARN(2), INFO(3), HINT(4).
Call with min_severity = WARN (2). Return count (should be 2: ERROR + WARN).
> Tip: filter vim.diagnostic.get(buf) by d.severity <= min_severity.

```lua
-- your code here
```
```expected
2
```
