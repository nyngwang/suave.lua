suave.lua
===

<span style="color:red;font-size:25px">S</span>ession?
L<span style="color:red;font-size:25px">ua</span>?
for <span style="color:red;font-size:25px">V</span>im
<span style="color:red;font-size:25px">E</span>nthusiast

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
  - I will put all your sessions into this folder.
  - Now you can manage your session along with your project.
- The core idea is pretty simple:
  - Suave.lua has one and only one menu. (Actually, it's a quickfix list)
  - You can use the menu to list all sessions of your current project.
  - To execute any command I provided, you have to open the menu first.
    - if you never open the menu, you will never encounter any trouble. (beginner-friendly :))
  - That's it.
- Addons:
  - [x] The menu can show the last-modified-timestamp of each session.
  - [x] Show how to achieve "auto-session" by `autocmd` in README.md.
  - [ ] The command for you to add note to each session file.

## Setup

packer.nvim:

```lua
use {
  'nyngwang/suave.lua', disable = false,
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
          function () end,
        },
        after_mksession = {},
      },
      restore_hooks = {
        before_source = {},
        after_source = {},
      }
    }

    -- Uncomment the following lines to enable project session automation
    -- NOTE: if you always call `tcd` instead of `cd` on all tabpages,
    --       you can stay in the current project and suave.lua will remember these paths.
    -- NOTE: the `vim.fn.argc() == 0` is required to exclude `git commit`.
    -- NOTE: the `not vim.v.event.changed_window` is required to exclude `:tabn`,`:tabp`.

    vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
      group = 'session.lua',
      pattern = '*',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          and not vim.v.event.dying -- safe leave
          then suave.store_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'DirChangedPre' }, {
      group = 'session.lua',
      pattern = 'global',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          and not vim.v.event.changed_window -- it's cd
          then suave.store_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'VimEnter' }, {
      group = 'session.lua',
      pattern = '*',
      callback = function ()
        if vim.fn.argc() == 0 -- not git
          then suave.restore_session(true)
        end
      end
    })
    vim.api.nvim_create_autocmd({ 'DirChanged' }, {
      group = 'session.lua',
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


