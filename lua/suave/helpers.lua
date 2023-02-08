local M = {}


function M.add_method_append(table)
  if type(table) ~= 'table' then return end
  function table:append(v)
    self[#self+1] = v
  end
end


return M
