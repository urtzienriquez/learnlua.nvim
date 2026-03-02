if vim.g.loaded_learnlua == 1 then
  return
end
vim.g.loaded_learnlua = 1

vim.api.nvim_create_user_command("Learn", function(args)
  require("learnlua").start(args.args ~= "" and args.args or nil)
end, { nargs = "?" })
