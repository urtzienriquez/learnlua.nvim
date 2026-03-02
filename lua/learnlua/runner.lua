local M = {}

local function normalize(s)
  return tostring(s):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")
end

local validators = {
  path = function(result)
    local s = tostring(result)
    return s:match("^/") ~= nil or s:match("^%a:[/\\]") ~= nil
  end,
}

M.check = function(code_lines, expected)
  local code = table.concat(code_lines, "\n")
  local last_printed = nil

  -- Capture helper
  local function capture_output(...)
    local parts = {}
    for i = 1, select("#", ...) do
      local v = select(i, ...)
      table.insert(parts, type(v) == "table" and vim.inspect(v) or tostring(v))
    end
    last_printed = table.concat(parts, "\t")
  end

  local sandbox = {
    vim = setmetatable({}, {
      __index = function(_, k)
        if k == "print" then
          return capture_output
        end
        return vim[k]
      end,
    }),
    print = capture_output,
    string = string,
    table = table,
    math = math,
    io = io,
    os = os,
    tostring = tostring,
    tonumber = tonumber,
    type = type,
    pairs = pairs,
    ipairs = ipairs,
    next = next,
    select = select,
    unpack = unpack or table.unpack,
    pcall = pcall,
    error = error,
    assert = assert,
    load = load,
    rawget = rawget,
    rawset = rawset,
    setmetatable = setmetatable,
    getmetatable = getmetatable,
  }

  local fn, err

  -- 1. If it's a single line and doesn't have 'return', try adding it
  -- don't know if it is a good idea
  if #code_lines == 1 and not code:match("^%s*return%s") then
    local return_code = "return " .. code
    fn = load(return_code, "exercise", "t", sandbox)
  end

  -- 2. If #1 failed or it's multi-line, load the code exactly as written
  if not fn then
    fn, err = load(code, "exercise", "t", sandbox)
  end

  if not fn then
    return false, "Syntax error: " .. err, nil
  end

  local ok, result = pcall(fn)
  if not ok then
    return false, "Runtime error: " .. tostring(result), nil
  end

  -- FALLBACK: Use printed output if return is nil
  if result == nil and last_printed ~= nil then
    result = last_printed
  end

  -- Final stringify for tables
  if type(result) == "table" then
    result = vim.inspect(result)
  end

  -- Validation
  local validator = validators[expected]
  if validator then
    if validator(result) then
      return true, "Correct!", result
    else
      return false, "expected a " .. expected .. ', got "' .. tostring(result) .. '"', result
    end
  end

  if normalize(result) == normalize(expected) then
    return true, "Correct!", result
  else
    return false, 'expected "' .. expected .. '"', result
  end
end

return M
