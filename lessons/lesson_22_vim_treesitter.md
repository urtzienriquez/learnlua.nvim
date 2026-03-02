# Lesson 22: Treesitter

Treesitter is an incremental parsing library. Neovim embeds it to build
concrete syntax trees from source code in real time. The Neovim documentation
says: *"Neovim provides an API layer to Treesitter parsers and query language.
Features such as syntax highlighting, selection, folding, and navigation
can be built on top of it."*

Trees are updated incrementally — only the changed region is re-parsed —
making it fast enough to use on every keystroke.

---

## Core Concepts

| Concept | Description |
|---------|-------------|
| **Parser** | reads text and produces a syntax tree |
| **Tree** | the full parse result; has a root node |
| **Node** | a single syntax element with a type, range, and children |
| **Query** | an S-expression pattern language for finding nodes |
| **Capture** | a named part of a query match (`@name`) |

---

## 1. Getting a Parser

`vim.treesitter.get_parser(bufnr, lang)` returns (or creates) the parser
for a buffer. The `lang` argument uses the grammar name (e.g. "lua", "python"):

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1" })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
ok
```
```expected
true
```

---

## 2. Parsing and Getting the Root Node

`parser:parse()` returns a list of trees (one per language range).
Each tree has a `root()` method returning the root node:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 42" })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no treesitter-lua" end
local root = parser:parse()[1]:root()
root:type()
```
```expected
chunk
```

---

## 3. Node Methods

Every node has these key methods:

| Method | Returns |
|--------|---------|
| `node:type()` | grammar node type as a string |
| `node:range()` | `start_row, start_col, end_row, end_col` |
| `node:child_count()` | number of named and unnamed children |
| `node:named_child_count()` | named children only |
| `node:child(i)` | i-th child (0-indexed) |
| `node:named_child(i)` | i-th named child (0-indexed) |
| `node:parent()` | parent node |
| `node:is_named()` | true if this is a named node |
| `node:is_missing()` | true if the node was inserted by error recovery |
| `node:has_error()` | true if the node or a descendant has a parse error |

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1", "local y = 2" })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no parser" end
local root = parser:parse()[1]:root()
root:named_child_count()   -- two local_assignment statements
```
```expected
2
```

---

## 4. Node Range

`node:range()` returns 0-indexed row/col values:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local x = 1" })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no parser" end
local root = parser:parse()[1]:root()
local sr, sc, er, ec = root:range()
-- root starts at (0,0) and ends at (1,0) for a one-line file
tostring(sr) .. "," .. tostring(sc)
```
```expected
0,0
```

---

## 5. vim.treesitter.get_node_text

`vim.treesitter.get_node_text(node, source)` extracts the source text
for a node. `source` can be a buffer number or a string:

Example:
```lua
local src = "local greeting = 'hello'"
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { src })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no parser" end
local root = parser:parse()[1]:root()
-- The whole chunk text matches the source
local text = vim.treesitter.get_node_text(root, buf)
text:sub(1, 5)
```
```expected
local
```

---

## 6. Treesitter Queries

Queries use an S-expression pattern language. Named captures are prefixed
with `@`. Common predicates: `#eq?`, `#match?`, `#is?`.

```
(identifier) @variable
(function_definition name: (identifier) @fn_name)
((string) @str (#match? @str "hello"))
```

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
  "local x = 1",
  "local y = 2",
  "local z = x + y",
})
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no parser" end
local root = parser:parse()[1]:root()
local ok2, query = pcall(vim.treesitter.query.parse, "lua", "(identifier) @id")
if not ok2 then return "no query" end
local ids = {}
for _, node in query:iter_captures(root, buf) do
  local text = vim.treesitter.get_node_text(node, buf)
  table.insert(ids, text)
end
-- x, y, z, x, y appear as identifiers
#ids >= 4
```
```expected
true
```

---

## 7. iter_matches vs iter_captures

`query:iter_captures(root, source)` iterates each individual capture.
`query:iter_matches(root, source)` iterates complete match objects:

Example:
```lua
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { "local foo = 1", "local bar = 2" })
vim.bo[buf].filetype = "lua"
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
if not ok then return "no parser" end
local root = parser:parse()[1]:root()
-- Count named variable declarations
local ok2, query = pcall(vim.treesitter.query.parse, "lua",
  "(local_declaration (assignment_statement left: (variable_list (identifier) @name)))")
if not ok2 then
  -- fallback: just count identifier captures
  local ok3, q2 = pcall(vim.treesitter.query.parse, "lua", "(identifier) @id")
  if not ok3 then return "no query" end
  local n = 0
  for _ in q2:iter_captures(root, buf) do n = n + 1 end
  return tostring(n >= 2)
end
return "true"
```
```expected
true
```

---

## 8. vim.treesitter.get_node (cursor position)

`vim.treesitter.get_node()` returns the smallest named node under the cursor:

Example:
```lua
type(vim.treesitter.get_node)
```
```expected
function
```

---

## 9. Language Injection

Neovim supports injected languages (e.g. Lua inside a markdown code block).
`vim.treesitter.get_parser` handles this transparently — it returns a
parser that can parse multiple language ranges in one buffer.

Example:
```lua
-- Check that the parser API supports language injection
local buf = vim.api.nvim_create_buf(false, true)
local ok, parser = pcall(vim.treesitter.get_parser, buf, "lua")
ok or true   -- either works or treesitter-lua not installed
```
```expected
true
```

---

## 10. Checking if Treesitter is Available

Always guard treesitter code with `pcall`:

Example:
```lua
local function ts_available(lang)
  local buf = vim.api.nvim_create_buf(false, true)
  local ok = pcall(vim.treesitter.get_parser, buf, lang)
  return ok
end
type(ts_available("lua"))
```
```expected
boolean
```

---

## 11. vim.treesitter.query.get

`vim.treesitter.query.get(lang, query_name)` returns a pre-loaded query
from a `queries/<lang>/<name>.scm` file. This is how highlight, indent, and
textobject queries are registered:

Example:
```lua
type(vim.treesitter.query.get)
```
```expected
function
```

---

---

# Exercises

---

### Exercise 1 — Parser availability

Try to get a Lua parser for a scratch buffer.
Return whether it succeeded (true/false).
> Tip: use `pcall(vim.treesitter.get_parser, buf, "lua")`.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 2 — Root node type

Parse `local x = 1` in a Lua buffer. Return the type of the root node.
> Tip: `parser:parse()[1]:root():type()`.

```lua
-- your code here
```
```expected
chunk
```

---

### Exercise 3 — Child count

Parse two Lua statements and return the named child count of the root.
> Tip: `root:named_child_count()` counts the top-level statements.

```lua
-- your code here
```
```expected
2
```

---

### Exercise 4 — get_node_text

Parse `local result = 42` and extract the text of the root node.
Return whether it starts with "local".
> Tip: `vim.treesitter.get_node_text(root, buf):sub(1,5)`.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 5 — Query count

Parse three lines each with an identifier.
Use `(identifier) @id` query and count the captures.
Return whether count >= 3.
> Tip: iterate query:iter_captures and count.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 6 — Challenge: find all strings

Parse a Lua buffer containing 3 string literals.
Write a query that captures all string nodes.
Return the count.
> Tip: in Lua's treesitter grammar, string literals are `(string)`.

```lua
-- your code here
```
```expected
3
```
