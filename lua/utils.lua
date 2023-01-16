local M = {}


function M.format_table(str)
  local level = 0
  local out = ''

  for c in str:gmatch'.' do
    if c == '{' or c == '[' then
      out = out .. c .. '\n'
      level = level+1
      out = out .. ('  '):rep(level)
    elseif c == '}' or c == ']' then
      level = level-1
      out = out .. '\n'
      out = out .. ('  '):rep(level)
      out = out .. c
    elseif c == ',' then
      out = out .. c .. '\n'
      out = out .. ('  '):rep(level)
    elseif c == ':' then
      out = out .. ': '
    else
      out = out .. c
    end
  end

  return out
end


return M
