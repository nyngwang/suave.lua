suave.lua
===

SUAVE is a quasi-acronym of "Session in LUA for Vim Enthusiasts."

(Not a decent name for a native speaker, but it's OK to be low-key so only me can enjoy this 🤫)

Suave.lua aims to be a standalone beginner-friendly auto-session plugin for NeoVim beginners.


## Intro.

https://user-images.githubusercontent.com/24765272/207277797-88682d65-fe22-41a1-9155-b20e23a0205b.mov

Suave.lua is all about project session automation, it can:

- `.setup()` callbacks on session store/restore.
- `.session_store()` multiple sessions for a single project.
- `.session_store()` mutliple sessions in your project folder.
- add simple note on session store.

Now you can:

- use `autocmd` + `.session_store(auto=true)` to achieve project session automation:
  - When `auto=true`, the naming process is skipped. So you can put the call inside `autocmd`.
- store/restore sessions by selecting them from the menu, no more command typing.


## Manual

- To start using suave.lua, just `mkdir .suave/` at your project root.
  - All your sessions will be stored into this folder.
  - Now you can keep all your sessions along with your project. (No more "where are my sessions?")
- The core idea is very simple:
  - Suave.lua has only one menu. (Actually, it's a quickfix list)
  - The menu lists all sessions created for your current project.
  - To execute any command I provided, you have to open the menu first.
    - if you never open the menu, you will never encounter any trouble. (No deletion by accidents)
- That's it.
- Addons:
  - [x] The menu can show the last-modified-timestamp of each session.
  - [x] Show how to achieve "auto-session" by `autocmd` in README.md.
  - [ ] The command for you to add note to each session file.


## Setup Example

Works with:
- folke/lazy.nvim: simply remove the `use`.
- wbthomason/packer.nvim: exact copy.

```lua
use {
  'nyngwang/suave.lua',
  config = function ()
    local suave = require('suave')
    suave.setup {
      -- split_on_top = true,
      -- menu_height = 13,
      store_hooks = {
        before_mksession = {
          function ()
            -- for _, w in ipairs(vim.api.nvim_list_wins()) do
            --   if vim.api.nvim_buf_get_option(vim.api.nvim_win_get_buf(w), 'ft') == 'neo-tree' then
            --     vim.api.nvim_win_close(w, false)
            --   end
            -- end
          end,
          function ()
            -- do your stuff here.
            -- WARN: DON'T call `vim.cmd('wa')` here.
            --       (leads to so silent error that basically disable auto-session!)
          end,
        },
        after_mksession = {},
      },
      restore_hooks = {
        before_source = {},
        after_source = {},
      }
    }
    -- Uncomment the following lines to enable project session automation.
    -- NOTE: if you always call `tcd` instead of `cd` on all tabpages,
    --       you can stay in the current project and suave.lua will remember these paths.
    -- NOTE: the `vim.fn.argc() == 0` is required to exclude `git commit`.
    -- NOTE: the `not vim.v.event.changed_window` is required to exclude `:tabn`,`:tabp`.
    -- INFO: While not included, it's recommended to use `group = ...` for your autocmd.
    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
      pattern = '*',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          and not vim.v.event.dying -- safe leave
          then suave.store_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'DirChangedPre' }, {
      pattern = 'global',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          and not vim.v.event.changed_window -- it's cd
          then suave.store_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'VimEnter' }, {
      pattern = '*',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          then suave.restore_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'DirChanged' }, {
      pattern = 'global',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          and not vim.v.event.changed_window -- it's cd
          then suave.restore_session(true)
        end
      end
    })
  end
}
```


## TODO

- be able to add one note for each session
- be able to change note for each session


