local M = {}

M.parse = function(filepath)
  local lines = vim.fn.readfile(filepath)
  local sections = {}
  local current = { prose = {}, code = {}, expected = {} }
  local prose_buffer = {}
  local mode = "prose"

  for _, line in ipairs(lines) do
    if line:match("^```lua") then
      -- If we already have code, the previous exercise is finished.
      -- Save it before starting the new one.
      if #current.code > 0 then
        table.insert(sections, {
          prose = current.prose,
          code = current.code,
          expected = #current.expected > 0 and table.concat(current.expected, "\n") or nil,
        })
        current = { prose = {}, code = {}, expected = {} }
      end

      -- The prose leading up to this code block belongs to THIS section
      current.prose = prose_buffer
      prose_buffer = {}
      mode = "code"
    elseif line:match("^```expected") then
      mode = "expected"
    elseif line:match("^```") then
      if mode == "expected" then
        -- An 'expected' block always terminates the current section
        table.insert(sections, {
          prose = current.prose,
          code = current.code,
          expected = table.concat(current.expected, "\n"),
        })
        current = { prose = {}, code = {}, expected = {} }
        prose_buffer = {}
      end
      mode = "prose"
    else
      if mode == "prose" then
        table.insert(prose_buffer, line)
      elseif mode == "code" then
        table.insert(current.code, line)
      elseif mode == "expected" then
        table.insert(current.expected, line)
      end
    end
  end

  -- Final flush for trailing content
  if #current.code > 0 or #prose_buffer > 0 then
    table.insert(sections, {
      prose = #current.prose > 0 and current.prose or prose_buffer,
      code = current.code,
      expected = #current.expected > 0 and table.concat(current.expected, "\n") or nil,
    })
  end

  return sections
end

return M
