local M = {}


function M.format_table(str)
  local level = 0
  local out = ''
  local _prev_is_closing_curly = false

  for c in str:gmatch'.' do
    if c == '{' then
      out = out .. '{\n'
      level = level+1
      out = out .. ('  '):rep(level)
    elseif c == '}' then
      level = level-1
      out = out .. '\n'
      out = out .. ('  '):rep(level)
      out = out .. '}'
      _prev_is_closing_curly = true
    elseif c == ',' and _prev_is_closing_curly then
      out = out .. ',\n'
      _prev_is_closing_curly = false
    elseif c == ':' then
      out = out .. ': '
    else
      out = out .. c
    end
  end

  return out
end


return M
