local U = require('suave.utils')
local M = {}


local function auto_save()
  vim.api.nvim_create_autocmd({ 'TextChanged', 'InsertLeave' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function ()
      if not require('suave').auto_save.enabled then return end
      if
        vim.bo.readonly
        or vim.api.nvim_buf_get_name(0) == ''
        or vim.bo.buftype ~= ''
        or U.table_contains(require('suave').auto_save.exclude_filetypes, vim.bo.filetype)
        or not (vim.bo.modifiable and vim.bo.modified)
      then return end
      vim.cmd('silent w')
    end
  })
end


function M.create_autocmds()
  auto_save()
end


return M
