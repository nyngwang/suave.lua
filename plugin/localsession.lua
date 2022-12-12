if vim.fn.has("nvim-0.7") == 0 then
  return
end

if vim.g.loaded_localsession ~= nil then
  return
end

require('localsession')

vim.g.loaded_localsession = 1
