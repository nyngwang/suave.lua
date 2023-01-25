local M = {}
M.PROJECT_NAME = 'suave'


function M.get_project_session_folder_path()
  -- This implicitly assume that every project should have one fixed `cd`.
  return string.format('%s/.%s', vim.fn.getcwd(-1, -1), M.PROJECT_NAME)
end


function M.folder_or_file_is_there(target_path)
  if not target_path then
    target_path = M.get_project_session_folder_path()
  end
  local yes, _, code = os.rename(target_path, target_path)
  return yes or (code == 13)
end


return M
