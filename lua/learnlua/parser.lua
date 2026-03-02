local M = {}

M.parse = function(filepath)
  local lines = vim.fn.readfile(filepath)
  local sections = {}
  local current = { prose = {}, code = {}, expected = {} }
  local mode = "prose"

  for _, line in ipairs(lines) do
    if line:match("^```lua") then
      mode = "code"
    elseif line:match("^```expected") then
      mode = "expected"
    elseif line:match("^```") then
      if mode == "code" then
        mode = "prose"
      elseif mode == "expected" then
        table.insert(sections, {
          prose = current.prose,
          code = current.code,
          expected = table.concat(current.expected, "\n"),
        })
        current = { prose = {}, code = {}, expected = {} }
        mode = "prose"
      end
    elseif mode == "prose" then
      table.insert(current.prose, line)
    elseif mode == "code" then
      table.insert(current.code, line)
    elseif mode == "expected" then
      table.insert(current.expected, line)
    end
  end

  return sections
end

return M
