if vim.fn.has("nvim-0.7") == 0 then
  return
end

if vim.g.loaded_suave ~= nil then
  return
end

require('suave')

vim.g.loaded_suave = 1
