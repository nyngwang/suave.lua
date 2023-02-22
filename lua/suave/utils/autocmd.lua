local U = require('suave.utils')
local M = {}


local function auto_save()
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function ()
      if
        vim.bo.readonly
        or vim.api.nvim_buf_get_name(0) == ''
        or vim.bo.buftype ~= ''
        or U.table_contains(require('suave').autocmds.auto_save.exclude_filetypes, vim.bo.filetype)
        or not (vim.bo.modifiable and vim.bo.modified)
      then return end
      vim.cmd('silent w')
    end
  })
end


local function switcher_on_cd()
  -- NOTE: `pattern = 'global'` prevent storing/restoring session on `:tcd`.
  -- NOTE: Vim's session will store those tabpage current-directory.
  vim.api.nvim_create_autocmd({ 'VimLeavePre' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function ()
      if
        vim.fn.argc() ~= 0 -- git or `nvim ...`.
        or vim.v.event.dying -- not safe leave.
      then return end
      require('suave.utils.json')._on_VimLeave = true
      require('suave').store_session(true)
      require('suave.utils.json')._on_VimLeave = false
    end
  })
  vim.api.nvim_create_autocmd({ 'VimEnter' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function ()
      if vim.fn.argc() ~= 0 -- git or `nvim ...`.
      then return end
      require('suave').restore_session(true)
    end
  })
  vim.api.nvim_create_autocmd({ 'DirChangedPre' }, {
    group = 'suave.lua',
    pattern = 'global', -- changed by `:cd`.
    callback = function ()
      if
        vim.fn.argc() ~= 0 -- git or `nvim ...`.
        or vim.v.event.changed_window -- by `:tabn`, `:tabp`.
      then return end
      require('suave').store_session(true)
    end
  })
  vim.api.nvim_create_autocmd({ 'DirChanged' }, {
    group = 'suave.lua',
    pattern = 'global', -- changed by `:cd`.
    callback = function ()
      if
        vim.fn.argc() ~= 0 -- git or `nvim ...`.
        or vim.v.event.changed_window -- by `:tabn`, `:tabp`.
      then return end
      require('suave').restore_session(true)
    end
  })
end


function M.create_autocmds(autocmds)
  if autocmds.auto_save.enabled then auto_save() end
  if autocmds.switcher_on_cd.enabled then switcher_on_cd() end
end


return M
