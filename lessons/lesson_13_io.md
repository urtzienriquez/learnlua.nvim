# Lesson 13: File I/O

Lua's `io` library provides file operations. The reference manual
distinguishes two models: the "simple model" with `io.read`/`io.write`
for stdin/stdout, and the "complete model" with explicit file handles.

---

## io.open

`io.open(filename, mode)` returns a file handle or nil + error message:

| Mode | Meaning |
|------|---------|
| `"r"` | read (default) |
| `"w"` | write (truncate) |
| `"a"` | append |
| `"r+"` | read+write (existing) |
| `"w+"` | read+write (truncate) |
| `"b"` | binary mode (combine with above) |

Example:
```lua
local path = vim.fn.tempname()
local f = io.open(path, "w")
type(f)
```
```expected
file
```

---

## Writing to a file

Example:
```lua
local path = vim.fn.tempname()
local f = assert(io.open(path, "w"))
f:write("hello\n")
f:write("world\n")
f:close()
-- Read it back
local r = assert(io.open(path, "r"))
local content = r:read("*a")
r:close()
content
```
```expected
hello
world

```

---

## f:read modes

| Mode | Returns |
|------|---------|
| `"*l"` or `"l"` | next line (without newline) — default |
| `"*L"` or `"L"` | next line (with newline) |
| `"*n"` or `"n"` | reads a number |
| `"*a"` or `"a"` | entire file |
| number | reads that many bytes |

Example:
```lua
local path = vim.fn.tempname()
local f = assert(io.open(path, "w"))
f:write("line1\nline2\nline3")
f:close()

local r = assert(io.open(path, "r"))
local first = r:read("l")
r:close()
first
```
```expected
line1
```

---

## Reading line by line

`f:lines()` returns an iterator:

Example:
```lua
local path = vim.fn.tempname()
local w = assert(io.open(path, "w"))
w:write("a\nb\nc\n")
w:close()

local lines = {}
for line in io.lines(path) do
  table.insert(lines, line)
end
table.concat(lines, ",")
```
```expected
a,b,c
```

---

## Append mode

Example:
```lua
local path = vim.fn.tempname()
local f = assert(io.open(path, "w"))
f:write("first\n")
f:close()

local a = assert(io.open(path, "a"))
a:write("second\n")
a:close()

local r = assert(io.open(path, "r"))
local content = r:read("*a")
r:close()
vim.trim(content)
```
```expected
first
second
```

---

## f:seek

`f:seek(whence, offset)` repositions the file pointer:
- `"set"`: from beginning
- `"cur"`: from current
- `"end"`: from end

Example:
```lua
local path = vim.fn.tempname()
local f = assert(io.open(path, "w+"))
f:write("hello world")
f:seek("set", 0)
local s = f:read("*a")
f:close()
s
```
```expected
hello world
```

---

## Error handling with io.open

`io.open` returns nil + message on failure — always check:

Example:
```lua
local f, err = io.open("/nonexistent/path/file.txt", "r")
f == nil
```
```expected
true
```

---

## vim.fn for file operations in Neovim

In Neovim plugins, `vim.fn` Vimscript functions are often more convenient
than raw `io`:

Example:
```lua
local path = vim.fn.tempname()
vim.fn.writefile({"line1", "line2", "line3"}, path)
local lines = vim.fn.readfile(path)
table.concat(lines, ",")
```
```expected
line1,line2,line3
```

---

## vim.fn.filereadable and vim.fn.isdirectory

Example:
```lua
local path = vim.fn.tempname()
vim.fn.writefile({"test"}, path)
vim.fn.filereadable(path) == 1
```
```expected
true
```

---

# Exercises

---

### Exercise 1

Write "hello" to a temp file and read it back. Return the content.
> Tip: use vim.fn.tempname() for a safe temp path.

```lua
-- your code here
```
```expected
hello
```

---

### Exercise 2

Write 3 lines to a file, then read them back one at a time using f:read("l").
Return the second line.
> Tip: call f:read("l") three times, keep the second return.

```lua
-- your code here
```
```expected
line2
```

---

### Exercise 3

Use io.lines to read a file containing "a\nb\nc" and count the lines.
> Tip: increment a counter in the for loop.

```lua
-- your code here
```
```expected
3
```

---

### Exercise 4

Use vim.fn.writefile and vim.fn.readfile to write and read a list of lines.
Write {"foo", "bar", "baz"} and return the length of the read result.
> Tip: vim.fn.readfile returns a table of strings.

```lua
-- your code here
```
```expected
3
```

---

### Exercise 5 — Challenge

Write a function `file_copy(src, dst)` that copies a file byte-by-byte.
Create a temp file, write "copied content", copy it, read the copy. Return its content.
> Tip: read "*a" from src, write to dst.

```lua
-- your code here
```
```expected
copied content
```
