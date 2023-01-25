local P = require('suave.utils.path')
local M = {}


function M.total_qflists()
  return vim.fn.getqflist({ nr='$' }).nr
end


function M.get_the_menu_id()
  for i = 1, M.total_qflists() do
    if vim.fn.getqflist({ nr=i, title=0 }).title == P.PROJECT_NAME then
      return vim.fn.getqflist({ nr=i, id=0 }).id
    end
  end
  local zero_on_success = vim.fn.setqflist({}, ' ', { nr='$', title=P.PROJECT_NAME })
  if zero_on_success ~= 0 then
    print('Suave: Failed to create suave menu!')
    return nil
  end
  return M.get_the_menu_id()
end


function M.refresh_the_menu()
  -- prepare items.
  local items = {}
  for dir in io.popen([[ find ]] .. P.get_project_session_folder_path() .. [[ -name '*.vim' ]]):lines() do
    items[#items+1] = {
      filename = vim.fn.fnamemodify(dir, ':t'),
      lnum = tonumber(string.sub(io.popen([[ stat -f %Sm -t %Y%m%d%H%M ]] .. dir):read(), 3, 10)), -- timestamp.
      -- TODO: should maintain a mapping file to store users' note on each session.
      text = '',
    }
  end
  -- populate items.
  vim.fn.setqflist({}, 'r', {
    id = M.get_the_menu_id(),
    items = items,
  })
end


function M.switch_to_the_menu()
  vim.cmd('chi ' .. vim.fn.getqflist({ id=M.get_the_menu_id(), nr=0 }).nr)
end


function M.get_the_menu_winid()
  local id = M.get_the_menu_id()
  if not id then return nil end
  local winid = vim.fn.getqflist({ id=id, winid=0 }).winid
  return winid > 0 and winid or nil
end


function M.disable_local_qf_highlight()
  local function _call_hl()
    vim.cmd([[
      hi __SUAVE_QF_DISABLE guibg=NONE guifg=Directory
      hi __SUAVE_NO_CURSORLINE guibg=NONE guifg=NONE
    ]])
  end
  local function _disable_local_qf_highlight()
    if M.cursor_is_at_the_menu() then
      _call_hl()
      vim.cmd('set winhl=QuickFixLine:__SUAVE_QF_DISABLE,CursorLine:__SUAVE_NO_CURSORLINE')
      _call_hl()
    end
  end
  vim.api.nvim_create_autocmd({ 'BufWinEnter', 'BufEnter' }, {
    group = 'suave.lua',
    pattern = '*',
    callback = function () _disable_local_qf_highlight() end
  })
end


function M.the_menu_did_build()
  return M.get_the_menu_id()
end


function M.the_menu_is_open()
  return M.get_the_menu_winid()
end


function M.cursor_is_at_the_menu()
  if M.get_the_menu_winid() == vim.api.nvim_get_current_win() then return true end
  return false
end


return M
