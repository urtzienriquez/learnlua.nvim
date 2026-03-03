local M = {}
local plugin_path = vim.fn.fnamemodify(debug.getinfo(1, "S").source:sub(2), ":p:h:h:h")

local parser = require("learnlua.parser")
local ui = require("learnlua.ui")
local runner = require("learnlua.runner")
local config = require("learnlua.config")

M.setup = function(opts)
  config.setup(opts)
end

M.start = function(args)
  local cfg = config.get()
  if not args then
    local filepath = plugin_path .. "/lessons/lesson_00_welcome.md"

    -- 1. Check if the buffer is already loaded
    local existing_buf = vim.fn.bufnr(filepath)
    if existing_buf ~= -1 and vim.api.nvim_buf_is_valid(existing_buf) then
      vim.api.nvim_set_current_buf(existing_buf)
      return
    end

    -- welcome has no exercises, just display it raw
    local lines = vim.fn.readfile(filepath)
    local buf = vim.api.nvim_create_buf(false, true)

    -- Safe name setting
    vim.api.nvim_buf_set_name(buf, filepath)
    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)

    vim.api.nvim_buf_set_lines(buf, 0, -1, false, lines)
    vim.bo[buf].filetype = "markdown"
    vim.bo[buf].modifiable = false
    vim.api.nvim_set_current_buf(buf)

    -- set path as a local option for the current window
    vim.opt_local.path = plugin_path .. "/lessons/"

    -- 1. Jump to Part I (Lua)
    vim.keymap.set("n", cfg.mappings.jump_lua, function()
      vim.fn.cursor(1, 1)
      if vim.fn.search([[### Part I]], "W") == 0 then
        print("Section 'Part I' not found")
      end
      vim.cmd("normal! zt")
    end, {})

    -- 2. Jump to Part II (Neovim API)
    vim.keymap.set("n", cfg.mappings.jump_nvim, function()
      vim.fn.cursor(1, 1)
      if vim.fn.search([[### Part II]], "W") == 0 then
        print("Section 'Part II' not found")
      end
      vim.cmd("normal! zt")
    end, {})

    -- gf opens the lesson under cursor
    vim.keymap.set("n", cfg.mappings.jump_lesson, function()
      local word = vim.fn.expand("<cWORD>")
      -- strip surrounding backticks and any punctuation
      local lesson = word:match("`([%w_%-]+)`")
      if not lesson then
        lesson = word:match("([%w_%-]+)$")
      end
      if lesson then
        M.start(lesson)
      else
        print("No lesson found under cursor")
      end
    end, { buffer = buf, noremap = true })

    vim.keymap.set("n", cfg.mappings.close_lesson, function()
      vim.api.nvim_buf_delete(buf, { force = true })
    end, { buffer = buf })
    return
  end

  local matches = vim.fn.glob(plugin_path .. "/lessons/lesson_*_" .. args .. ".md", false, true)
  local filepath = matches[1]
  local ok, sections = pcall(parser.parse, filepath)
  if not ok or #sections == 0 then
    print("Lesson not found or empty: " .. args)
    return
  end

  ui.open(sections, runner, filepath)
end

return M
