local M = {}

M.defaults = {
  mappings = {
    open_editor = "<CR>", -- Inside code block
    submit_code = "<CR>", -- Inside editor
    test_code = "tc", -- Inside editor
    close_editor = "q",
    close_lesson = "q",
    go_welcome = "gO",
    jump_lua = "gl",
    jump_nvim = "gn",
    jump_next = "gn",
    jump_previous = "gp",
    jump_lesson = "<CR>", -- In lesson list
  },
}

M.options = vim.deepcopy(M.defaults)

function M.setup(user_opts)
  -- Merge user_opts into defaults
  M.options = vim.tbl_deep_extend("force", M.defaults, user_opts or {})
end

function M.get()
  return M.options
end

return M
