local M = {}

local LSP_SETTINGS = {
  Lua = {
    runtime = { version = "LuaJIT" },
    workspace = {
      library = vim.api.nvim_get_runtime_file("", true),
      checkThirdParty = false,
    },
    diagnostics = { globals = { "vim" } },
  },
}

local function start_lsp(buf)
  -- Safety: only attach to lua buffers, never markdown or anything else
  if vim.bo[buf].filetype ~= "lua" then
    return
  end

  -- If already attached to THIS buffer specifically, do nothing
  local already = vim.lsp.get_clients({ name = "lua_ls", bufnr = buf })
  if #already > 0 then
    return
  end

  -- If the server is running but not yet attached to this buffer, just attach
  local existing = vim.lsp.get_clients({ name = "lua_ls" })
  if #existing > 0 then
    vim.lsp.buf_attach_client(buf, existing[1].id)
    return
  end

  -- Server not running yet — find the binary
  local candidates = {
    vim.fn.stdpath("data") .. "/mason/bin/lua-language-server",
    vim.fn.exepath("lua-language-server"),
  }

  local cmd
  for _, path in ipairs(candidates) do
    if path ~= "" and vim.fn.executable(path) == 1 then
      cmd = path
      break
    end
  end

  if not cmd then
    vim.notify("learnlua: lua-language-server not found, LSP unavailable", vim.log.levels.WARN)
    return
  end

  local client_id = vim.lsp.start({
    name = "lua_ls",
    cmd = { cmd },
    root_dir = vim.fn.getcwd(),
    settings = LSP_SETTINGS,
  }, { bufnr = buf })

  if not client_id then
    vim.notify("learnlua: failed to start lua-language-server", vim.log.levels.WARN)
  end

  if client_id then
    vim.lsp.buf_attach_client(buf, client_id)
  end
end

local function close_editor(win, buf, lesson_win)
  vim.api.nvim_win_close(win, true)
  vim.api.nvim_buf_delete(buf, { force = true })
  vim.api.nvim_set_current_win(lesson_win)
end

M.open = function(sections, runner, filepath)
  local cfg = require("learnlua.config").get()
  local ns = vim.api.nvim_create_namespace("learnlua")
  local lesson_buf = vim.api.nvim_create_buf(false, true)
  local exercise_ranges = {}
  local all_lines = {}

  if filepath then
    local existing = vim.fn.bufnr(filepath)
    if existing ~= -1 and vim.api.nvim_buf_is_valid(existing) then
      vim.api.nvim_set_current_buf(existing)
      return
    end
  end

  if filepath then
    vim.api.nvim_buf_set_name(lesson_buf, filepath)
  end

  for _, section in ipairs(sections) do
    vim.list_extend(all_lines, section.prose)
    vim.list_extend(all_lines, { "", "```lua" })
    local code_start = #all_lines + 1
    vim.list_extend(all_lines, section.code)
    local code_end = #all_lines
    vim.list_extend(all_lines, { "```", "" })
    table.insert(exercise_ranges, {
      start = code_start - 1,
      finish = code_end - 1,
      section = section,
    })
  end

  vim.api.nvim_buf_set_lines(lesson_buf, 0, -1, false, all_lines)
  vim.bo[lesson_buf].filetype = "markdown"
  vim.bo[lesson_buf].modifiable = false
  vim.api.nvim_set_current_buf(lesson_buf)
  local lesson_win = vim.api.nvim_get_current_win()

  local function show_feedback(marker, correct, msg, result)
    local lines = vim.api.nvim_buf_get_lines(lesson_buf, 0, -1, false)
    local current_closing = marker
    for i = marker, #lines - 1 do
      if lines[i + 1] and lines[i + 1]:match("^```$") then
        current_closing = i
        break
      end
    end

    local display_result = tostring(result):gsub("\n", " "):gsub("%s+", " "):gsub("^%s+", ""):gsub("%s+$", "")

    vim.api.nvim_buf_clear_namespace(lesson_buf, ns, current_closing, current_closing + 2)

    local virt = {}
    if correct ~= nil then
      table.insert(virt, { { "  result: " .. display_result, "Comment" } })
    end
    table.insert(virt, {
      {
        correct == true and "  ✓ Correct!" or correct == false and "  ✗ " .. msg or "  ⓘ " .. msg,
        correct == true and "DiagnosticOk" or correct == false and "DiagnosticError" or "DiagnosticInfo",
      },
    })

    vim.api.nvim_buf_set_extmark(lesson_buf, ns, current_closing + 1, 0, {
      virt_lines_above = true,
      virt_lines = virt,
    })
  end

  local function get_block_at_cursor()
    local cursor = vim.api.nvim_win_get_cursor(lesson_win)[1] - 1
    local lines = vim.api.nvim_buf_get_lines(lesson_buf, 0, -1, false)

    local marker, block_start
    for i = cursor, 0, -1 do
      if lines[i + 1] and lines[i + 1]:match("^```lua") then
        marker, block_start = i, i + 1
        break
      end
    end

    if not marker then
      return nil, nil, nil, nil
    end

    -- Find the closing ``` that belongs to THIS block (first one after the opening)
    local block_end, closing
    for i = marker + 1, #lines - 1 do
      if lines[i + 1] and lines[i + 1]:match("^```") then
        closing, block_end = i, i - 1
        break
      end
    end

    if not closing then
      return nil, nil, nil, nil
    end

    -- Guard: cursor must actually be inside this block
    if cursor < block_start or cursor > block_end then
      return nil, nil, nil, nil
    end

    local exercise_index = 0
    for i = 0, marker do
      if lines[i + 1] and lines[i + 1]:match("^```lua") then
        exercise_index = exercise_index + 1
      end
    end

    local section = exercise_ranges[exercise_index] and exercise_ranges[exercise_index].section
    local code_lines = vim.api.nvim_buf_get_lines(lesson_buf, block_start, block_end + 1, false)
    return code_lines, section, marker, block_start
  end

  local function open_editor(code_lines, section, marker, block_start)
    if not section.expected then
      show_feedback(marker, nil, "Nothing to evaluate in this chunk", "")
      return
    end
    local editor_buf = vim.api.nvim_create_buf(false, true)
    vim.api.nvim_buf_set_name(editor_buf, vim.fn.tempname() .. ".lua")
    vim.api.nvim_buf_set_lines(editor_buf, 0, -1, false, code_lines)

    -- Set filetype BEFORE calling start_lsp so the filetype guard works correctly
    vim.bo[editor_buf].filetype = "lua"
    start_lsp(editor_buf)

    local function sync_to_lesson()
      local editor_lines = vim.api.nvim_buf_get_lines(editor_buf, 0, -1, false)
      local lesson_lines = vim.api.nvim_buf_get_lines(lesson_buf, 0, -1, false)
      local current_end = block_start
      for i = block_start, #lesson_lines - 1 do
        if lesson_lines[i + 1] and lesson_lines[i + 1]:match("^```$") then
          current_end = i - 1
          break
        end
      end
      vim.bo[lesson_buf].modifiable = true
      vim.api.nvim_buf_set_lines(lesson_buf, block_start, current_end + 1, false, editor_lines)
      vim.bo[lesson_buf].modifiable = false
    end

    vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI" }, {
      buffer = editor_buf,
      callback = sync_to_lesson,
    })

    vim.cmd("botright 15split")
    local editor_win = vim.api.nvim_get_current_win()
    vim.api.nvim_win_set_buf(editor_win, editor_buf)

    vim.keymap.set("n", cfg.mappings.submit_code, function()
      local lines = vim.api.nvim_buf_get_lines(editor_buf, 0, -1, false)
      local correct, msg, result = runner.check(lines, section.expected)
      show_feedback(marker, correct, msg, result)
      if correct then
        close_editor(editor_win, editor_buf, lesson_win)
      end
    end, { buffer = editor_buf })

    vim.keymap.set("n", cfg.mappings.close_editor, function()
      close_editor(editor_win, editor_buf, lesson_win)
    end, { buffer = editor_buf })
  end

  vim.keymap.set("n", cfg.mappings.open_editor, function()
    local code_lines, section, marker, block_start = get_block_at_cursor()
    if not code_lines or not section then
      print("Place your cursor inside a code block and press <CR>")
      return
    end
    open_editor(code_lines, section, marker, block_start)
  end, { buffer = lesson_buf })

  vim.keymap.set("n", cfg.mappings.close_lesson, function()
    vim.api.nvim_buf_delete(lesson_buf, { force = true })
  end, { buffer = lesson_buf })

  vim.keymap.set("n", cfg.mappings.go_welcome, function()
    vim.cmd("Learn")
  end, { buffer = lesson_buf })
end

return M
