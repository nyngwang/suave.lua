local P = require('suave.utils.path')
local M = {}
M.PROJECT_JSON_NAME = string.format('%s_storage', P.PROJECT_NAME)


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


function M.get_project_json_path()
  return string.format('%s/%s.json', P.get_project_session_folder_path(), M.PROJECT_JSON_NAME)
end


function M.read_from_project_json()
  local fp = io.open(M.get_project_json_path(), 'r')
  if not fp then
    print("Suave: fetching file handler for reading ... failed!")
    return false
  end
  local data = vim.json.decode(fp:read("*a"))
  fp:close()
  print("Suave: reading project file ... succeeded!")
  return true, data
end


function M.write_to_project_json(data)
  if type(data) ~= 'table' then
    print("Suave: data should be a Lua table!")
    return false
  end
  local fp = io.open(M.get_project_json_path(), 'w+')
  if not fp then
    print("Suave: fetching file handler for writing ... failed!")
    return false
  end
  fp:write(M.format_table(vim.json.encode(data)))
  fp:close()
  print("Suave: write to project file ... success!")
  return true
end


function M.get_or_create_project_file_data()
  -- create.
  if not P.folder_or_file_is_there(M.get_project_json_path()) then
    vim.cmd(string.format('!touch %s', M.get_project_json_path()))
    M.write_to_project_json({})
    print("Suave: A default project file has been created under the `.suave/` folder!")
    return true, {}
  end

  -- or get.
  local succeeded, read = M.read_from_project_json()
  if not succeeded then return false end
  print("Suave: A default project file has been created under `.suave/` folder!")
  return true, read
end


return M
