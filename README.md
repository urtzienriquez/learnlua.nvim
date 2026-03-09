# learnlua.nvim

An interactive Lua and Neovim API tutorial — right inside your editor.

Requirements

- lua-language-server (optional, for LSP support — install via Mason or your system package manager)

---

## Installation

With lazy.nvim:

```lua
return {
  "urtzienriquez/learnlua.nvim",
  cmd = "Learn",
}
```

---

## Usage

Open the welcome page and table of contents:

```lua
:Learn
```

Open a specific lesson:

```lua
:Learn basics
:Learn coroutines
:Learn vim_lsp
```

---

## Keymaps

### Table of contents

| Key    | Action                           |
| ------ | -------------------------------- |
| `<CR>` | Open the lesson under the cursor |
| `gl`   | Jump to Part I — Lua language    |
| `gn`   | Jump to Part II — Neovim API     |
| `q`    | Close                            |

### Inside a lesson

| Key    | Action                                                  |
| ------ | ------------------------------------------------------- |
| `<CR>` | Open the exercise editor for the block under the cursor |
| `gO`   | Return to the table of contents                         |
| `q`    | Close the lesson                                        |

### Inside the exercise editor

| Key    | Action                             |
| ------ | ---------------------------------- |
| `<CR>` | Run your code and check the result |
| `tc`   | Run your code to test (test_code)  |
| `q`    | Close and return to the lesson     |

### change default keymaps

```lua
return {
  "urtzienriquez/learnlua.nvim",
  dev = true,
  cmd = "Learn",
  opts = {
    -- default keymaps
    mappings = {
      open_editor = "<CR>", -- Inside code block
      submit_code = "<CR>", -- Inside editor
      test_code = "tc",
      close_editor = "q",
      close_lesson = "q",
      go_welcome = "gO",
      jump_lua = "gl",
      jump_nvim = "gn",
      jump_lesson = "<CR>", -- In lesson list
    },
  },
}
```

---

## How it works

Each lesson is a markdown file with embedded code blocks and expected outputs. Press `<CR>` on any block to open a small split editor. Edit the code, press `<CR>` to run it — virtual text shows `✓` Correct! or `✗` with the difference between expected and actual output. Passing an exercise closes the editor automatically.

Inside of code editor, you can use "tc" (in normal mode) to test your code and see all the outputs of print commands. 

LSP completions and diagnostics are available in the exercise editor if lua-language-server is installed.

---

## Lessons

Part I — Lua Language

- basics
- strings
- tables
- control_flow
- functions
- oop
- metatables
- iterators
- patterns
- error_handling
- coroutines
- modules
- io

Part II — Neovim API

- vim_api
- vim_options
- vim_keymaps
- vim_autocommands
- vim_buffers
- vim_highlights
- vim_usercmds
- vim_lsp
- vim_treesitter
- vim_config
- vim_plugin

---

## License

GNU General Public License v3.0 — see [LICENSE](LICENSE).
