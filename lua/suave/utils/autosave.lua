local U = require('suave.utils')
local M = {}


function M.create_autocmd_autosave()
  vim.api.nvim_create_autocmd({ 'TextChanged' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function ()
      if not require('suave').auto_save.enabled then return end
      if
        vim.bo.readonly
        or U.table_contains(require('suave').auto_save.exclude_filetypes, vim.bo.filetype)
        or U.table_contains(require('suave').auto_save.exclude_buftypes, vim.bo.buftype)
        or not (vim.bo.modifiable and vim.bo.modified)
      then return end
      vim.cmd('silent w')
    end
  })
end


return M
