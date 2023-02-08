suave.lua
===


suave.lua aims to be a minimal,
beginner-friendly **project session automation** plugin
for NeoVim beginners.

(The name `SUAVE` is a quasi-acronym of "`S`ession in L`UA` for `V`im `E`nthusiasts".)  


## Intro.


https://user-images.githubusercontent.com/24765272/217663121-7880060f-728c-463f-9063-ecdbafb00a06.mov



suave.lua is all about project session automation, it can:

- `.setup()` callbacks on session store/restore.
- `.session_store()` multiple sessions for a single project.
- `.session_store()` mutliple sessions in your project folder.
- it supports storing a custom **JSON** for each of your project.


Now you can:

- Use `autocmd` + `.session_store(auto=true)` to achieve project session automation:
  - when `auto=true`, the naming process is skipped, so it's safe to call it inside a `autocmd`.
- Use the JSON data to...
  - restore the colortheme for each project.
  - restore the pomodoro timer for each project.
  - restore anything needed to restore a plugin.


## Manual

- To start using suave.lua, just `mkdir .suave/` at your project root.
  - all your sessions will be stored into this folder.
  - no more question like "where does this plugin store all my sessions?"
- The core idea is very simple:
  - suave.lua has only one menu. (a quickfix list)
  - The menu lists all sessions created for your current project.
  - To execute any command I provided, you have to open the menu first.
    - if you never open the menu, you will never delete your sessions in Neovim upon bugs.
- That's it.


#### Addons:

- [x] The menu can show the last-modified-timestamp of each session.
- [x] Show how to achieve "auto-session" by `autocmd` in README.md.
- [ ] The command for you to add note to each session file.


## Setup Example

Notes for different plugin managers:
- [folke/lazy.nvim](https://github.com/folke/lazy.nvim): simply remove the `use`.
- [wbthomason/packer.nvim](https://github.com/wbthomason/packer.nvim): exact copy.


```lua
use {
  'nyngwang/suave.lua',
  config = function ()
    require('suave').setup {
      -- menu_height = 6,
      auto_save = {
        enabled = true,
        -- exclude_filetypes = {},
      },
      store_hooks = {
        -- WARN: DON'T call `vim.cmd('wa')` here. Use `setup.auto_save` instead. (See #4)
        before_mksession = {
          -- function ()
          --   -- `rcarriga/nvim-dap-ui`.
          --   require('dapui').close()
          -- end,
          -- function ()
          --   -- `nvim-neo-tree/neo-tree.nvim`.
          --   for _, w in ipairs(vim.api.nvim_list_wins()) do
          --     if vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(w), 'ft') == 'neo-tree' then
          --       vim.api.nvim_win_close(w, false)
          --     end
          --   end
          -- end,
        },
        after_mksession = {
          -- NOTE: the `data` param is Lua table, which will be stored in json format under `.suave/` folder.
          function (data)
            -- store current colorscheme.
            data.colorscheme = vim.g.colors_name
          end,
        },
      },
      restore_hooks = {
        after_source = {
          function (data)
            if not data then return end
            -- restore colorscheme.
            vim.cmd(string.format([[
              color %s
              doau ColorScheme %s
            ]], data.colorscheme, data.colorscheme))
          end,
        },
      }
    }
  end
}
```
