local P = require('suave.utils.path')
local M = {}
M._on_VimLeave = false
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
  if not P.folder_or_file_is_there() then
    if not M._on_VimLeave then
      print("Suave: Failed to find the `.suave/` folder.")
    end
    return { false, nil }
  end

  local fp = io.open(M.get_project_json_path(), 'r')
  if not fp then
    if not M._on_VimLeave then
      print("Suave: Failed to read the project JSON.")
    end
    return { false, nil }
  end
  local data = vim.json.decode(fp:read("*a"))
  fp:close()
  if not M._on_VimLeave then
    print("Suave: Succeeded in reading the project JSON!")
  end
  return { true, data }
end


function M.write_to_project_json(data)
  if not P.folder_or_file_is_there() then
    if not M._on_VimLeave then
      print("Suave: Failed to find the `.suave/` folder.")
    end
    return false
  end

  if type(data) ~= 'table' then
    if not M._on_VimLeave then
      print("Suave: The input of `write_to_project_json` should be a Lua table...")
    end
    return false
  end
  local fp = io.open(M.get_project_json_path(), 'w+')
  if not fp then
    if not M._on_VimLeave then
      print("Suave: Failed to write to the project JSON...")
    end
    return false
  end
  fp:write(M.format_table(vim.json.encode(data)))
  fp:close()
  if not M._on_VimLeave then
    print("Suave: Succeeded in writing to the project JSON!")
  end
  return true
end


function M.get_or_create_project_file_data()
  if not P.folder_or_file_is_there() then
    if not M._on_VimLeave then
      print("Suave: Failed to find the `.suave/` folder.")
    end
    return { false, nil }
  end

  -- create.
  if not P.folder_or_file_is_there(M.get_project_json_path()) then
    vim.cmd(string.format('!touch %s', M.get_project_json_path()))
    M.write_to_project_json({})
    if not M._on_VimLeave then
      print("Suave: A default project file has been created under the `.suave/` folder!")
    end
    return { true, {} }
  end

  -- or get.
  local succeeded, read = unpack(M.read_from_project_json())
  if not succeeded then return { false, nil } end
  return { true, read }
end


return M
