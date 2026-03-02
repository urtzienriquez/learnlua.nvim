# Lesson 10: Error Handling

The Lua reference manual explains: "Lua uses the throw/catch mechanism
for error handling via the functions error, pcall, and xpcall."

Unlike languages with exception hierarchies, Lua errors are just values —
any type can be thrown. The absence of a stack unwinding mechanism means
errors are handled at the call site, not bubbled up automatically.

---

## error()

`error(msg, level)` raises an error. The message can be any value.
`level` controls where the error "points":
- 1 (default): the function calling error
- 2: the function that called the function calling error
- 0: no position info

Example:
```lua
local ok, err = pcall(function()
  error("something went wrong")
end)
type(err)
```
```expected
string
```

---

## pcall — protected call

`pcall(fn, ...)` calls `fn` with the given args in protected mode.
Returns `true, results...` on success, or `false, error_object` on failure:

Example:
```lua
local ok, val = pcall(function() return 2 + 2 end)
ok .. "/" .. val
```
```expected
true/4
```

Example:
```lua
local ok, err = pcall(function() error("oops") end)
ok
```
```expected
false
```

---

## Error messages include location

By default, `error(msg)` prepends file:line to the message:

Example:
```lua
local ok, err = pcall(function()
  error("test error")
end)
-- err will be something like "input:2: test error"
type(err) == "string" and err:find("test error") ~= nil
```
```expected
true
```

---

## Throwing non-string errors

Errors can be any value — tables are useful for structured errors:

Example:
```lua
local ok, err = pcall(function()
  error({ code = 404, msg = "not found" })
end)
err.code
```
```expected
404
```

---

## error() level 2 — blame the caller

When a helper function detects bad input, level 2 makes the error
point to the caller of the helper, not the helper itself:

Example:
```lua
local function expect_string(val, arg_name)
  if type(val) ~= "string" then
    error("bad argument #1 (" .. arg_name .. "): string expected, got " .. type(val), 2)
  end
  return val
end
local ok, err = pcall(expect_string, 42, "name")
ok
```
```expected
false
```

---

## xpcall — with a message handler

`xpcall(fn, handler, ...)` is like pcall but the handler receives the
raw error before it's returned. Use it to add a stack traceback:

Example:
```lua
local ok, err = xpcall(
  function() error("raw") end,
  function(e) return "CAUGHT: " .. tostring(e) end
)
err:sub(1, 6)
```
```expected
CAUGHT
```

---

## debug.traceback in xpcall

The most common use of xpcall is to capture the traceback:

Example:
```lua
local ok, err = xpcall(
  function() error("boom") end,
  debug.traceback
)
type(err) == "string"
```
```expected
true
```

---

## assert()

`assert(v, msg)` returns v if truthy, otherwise raises error with msg.
Great for preconditions:

Example:
```lua
local function divide(a, b)
  assert(b ~= 0, "division by zero")
  return a / b
end
local ok, err = pcall(divide, 10, 0)
ok
```
```expected
false
```

Example:
```lua
-- assert returns its arguments on success
local x = assert(42, "won't error")
x
```
```expected
42
```

---

## Nested pcall

Inner pcall errors don't propagate unless you re-raise them:

Example:
```lua
local inner_ok
local outer_ok = pcall(function()
  inner_ok = pcall(function() error("inner") end)
  return "outer ok"
end)
tostring(outer_ok) .. "/" .. tostring(inner_ok)
```
```expected
true/false
```

---

## Re-raising errors

To propagate an error after inspecting it, call `error` again:

Example:
```lua
local function safe_run(fn)
  local ok, err = pcall(fn)
  if not ok then
    if type(err) == "table" and err.code == 404 then
      return "not_found"
    end
    error(err, 0)   -- re-raise other errors
  end
  return "ok"
end
safe_run(function() error({code=404}) end)
```
```expected
not_found
```

---

## Error objects with tostring

If you throw a table as an error and want a nice message:

Example:
```lua
local AppError = {}
AppError.__index = AppError
AppError.__tostring = function(e)
  return string.format("[%s] %s", e.code, e.message)
end
function AppError.new(code, msg)
  return setmetatable({code=code, message=msg}, AppError)
end

local ok, err = pcall(function()
  error(AppError.new("AUTH", "not logged in"), 0)
end)
tostring(err)
```
```expected
[AUTH] not logged in
```

---

# Exercises

---

### Exercise 1

Write a `safe_divide(a, b)` that raises an error when b is 0.
Catch it with pcall and return false if error was caught.
> Tip: error("division by zero") in the function body.

```lua
-- your code here
```
```expected
false
```

---

### Exercise 2

Use `assert` to validate that a value is a number >= 0.
Call it with -5. Catch the error and return true if caught.
> Tip: assert(n >= 0, "must be non-negative").

```lua
-- your code here
```
```expected
true
```

---

### Exercise 3

Throw a table error {type="NotFound", item="key"}.
Catch it and return err.type.
> Tip: error(table, 0) throws without adding location.

```lua
-- your code here
```
```expected
NotFound
```

---

### Exercise 4

Use xpcall to catch an error and return a message that starts with "CAUGHT:".
Return the first 6 characters.
> Tip: xpcall(fn, handler); handler receives the raw error.

```lua
-- your code here
```
```expected
CAUGHT
```

---

### Exercise 5

Write a `retry(fn, n)` function that retries fn up to n times,
returning true on first success or false if all fail.
Use a function that fails twice then succeeds.
> Tip: loop with pcall; break on success.

```lua
-- your code here
```
```expected
true
```

---

### Exercise 6 — Challenge

Write a simple Result monad: `ok(v)` and `err(msg)` that return
tagged tables, and `is_ok(r)` that checks the tag.
Chain two operations where the second one fails.
Return is_ok of the final result (should be false).
> Tip: { tag = "ok", value = v } and { tag = "err", message = msg }.

```lua
-- your code here
```
```expected
false
```
