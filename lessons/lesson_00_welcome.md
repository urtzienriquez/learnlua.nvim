# learnlua.nvim

An interactive Lua and neovim API tutorial — right inside your editor.

`gl`: to jump to lua lesson list
`gn`: to jump to lua in neovim lesson list
`<CR>`: on top of a lesson name to jump to that lesson
`gO`: in the lesson to return here

---

## How to use this plugin

- **Open a lesson**: Place your cursor on a lesson filename below and press `<CR>`.
- **Edit code**: Inside a lesson, press `<CR>` on any code block to open the exercise buffer.
- **Execute**: Press `<CR>` in normal mode (or your configured run key) to run your code against the test.
- **Evaluate**: To pass an exercise, your code must "output" a value. You can do this in two ways:
  - **Return**: Use `return value`.
  - **Print**: Use `print(value)` or `vim.print(value)` (The runner captures the last thing printed).
- **Feedback**: Virtual text shows ✓ with your result, or ✗ showing the difference between Expected and Actual.
- **Return to ToC**: Press `gO` in a lesson to return here.
- **Exit**: Press `q` to close the exercise or the lesson.

> A Note on "Naked" Expressions:
> In Lua, every line in a multi-line script must be a valid statement. Avoid leaving a value alone on a line without a print or return prefix, as this will cause a Syntax Error before the code can even be checked.

---

## Lessons

### Part I — Lua Language

1. `basics` | Types, variables, operators, nil, booleans, numbers, strings, coercions
2. `strings` | String library, format, find, match, gmatch, gsub, byte/char, reverse
3. `tables` | Array and dict usage, insert/remove/sort/concat, next, table.move, unpack
4. `control_flow` | if/elseif/else, while, repeat/until, numeric for, generic for, break, goto
5. `functions` | Closures, multiple returns, variadic args, tail calls, upvalues, HOF
6. `oop` | Class pattern, constructors, inheritance, method chaining, mixins
7. `metatables` | All metamethods, __index/__newindex, operator overloading, __call
8. `iterators` | Generic for internals, stateless/stateful iterators, coroutine iterators
9. `patterns` | Pattern language, character classes, captures, anchors, balanced match
10. `error_handling` | pcall, xpcall, error(), assert, error objects, stack traces
11. `coroutines` | create/resume/yield/wrap, producers, consumers, pipelines
12. `modules` | require, package.path, package.loaded, module patterns
13. `io` | io.open, file handles, read modes, write, seek, tmpfile, vim.fn utilities

### Part II — Neovim API

14. `vim_api` | vim._ namespace, inspect, fn, api, tbl_ utilities, notify, schedule
15. `vim_options` | vim.opt/o/bo/wo, vim.g/b/w/t/env, scopes, option metadata
16. `vim_keymaps` | keymap.set/del, all modes, buffer-local, expr, which-key desc
17. `vim_autocommands` | create_autocmd, augroups, events, patterns, once, exec_autocmds
18. `vim_buffers` | create_buf, lines API, names, options, windows, tabs, floating windows
19. `vim_highlights` | Highlight groups, namespaces, extmarks, virtual text, virt_lines, signs
20. `vim_usercmds` | create_user_command, nargs, bang, range, complete, buffer-local
21. `vim_lsp` | vim.diagnostic, severities, set/get/reset/config, lsp.buf functions
22. `vim_treesitter` | Parsers, trees, nodes, queries, iter_captures, get_node_text
23. `vim_config` | init.lua architecture, lazy loading, stdpath, filetype config, scheduling
24. `vim_plugin` | Plugin layout, config module, tbl utilities, deepcopy, health checks

---
