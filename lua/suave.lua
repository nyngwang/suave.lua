vim.api.nvim_create_augroup('suave.lua', { clear = true })
---------------------------------------------------------------------------------------------------
local M = {}
local PROJECT_NAME = 'suave'
local PROJECT_DATA_NAME = 'storage'


local function get_project_suave_path()
  -- This implicitly assume that every project should have one fixed `cd`.
  return string.format('%s/.%s', vim.fn.getcwd(-1, -1), PROJECT_NAME)
end


local function total_qflists()
  return vim.fn.getqflist({ nr='$' }).nr
end


local function get_the_menu_id()
  for i = 1, total_qflists() do
    if vim.fn.getqflist({ nr=i, title=0 }).title == PROJECT_NAME then
      return vim.fn.getqflist({ nr=i, id=0 }).id
    end
  end
  local zero_on_success = vim.fn.setqflist({}, ' ', { nr='$', title=PROJECT_NAME })
  if zero_on_success ~= 0 then
    print('Suave: Failed to create suave menu!')
    return nil
  end
  return get_the_menu_id()
end


local function refresh_the_menu()
  -- prepare items.
  local items = {}
  for dir in io.popen([[ find ]] .. get_project_suave_path() .. [[ -name '*.vim' ]]):lines() do
    items[#items+1] = {
      filename = vim.fn.fnamemodify(dir, ':t'),
      lnum = tonumber(string.sub(io.popen([[ stat -f %Sm -t %Y%m%d%H%M ]] .. dir):read(), 3, 10)), -- timestamp
      -- TODO: should maintain a mapping file to store users' note on each session.
      text = '',
    }
  end
  -- populate items.
  vim.fn.setqflist({}, 'r', {
    id = get_the_menu_id(),
    items = items,
  })
end


local function switch_to_the_menu()
  vim.cmd('chi ' .. vim.fn.getqflist({ id=get_the_menu_id(), nr=0 }).nr)
end


local function the_menu_did_build()
  return get_the_menu_id()
end


local function get_the_menu_winid()
  local id = get_the_menu_id()
  if not id then return nil end
  local winid = vim.fn.getqflist({ id=id, winid=0 }).winid
  return winid > 0 and winid or nil
end


local function the_menu_is_open()
  return get_the_menu_winid()
end


local function cursor_is_at_the_menu()
  if get_the_menu_winid() == vim.api.nvim_get_current_win() then return true end
  return false
end


local function disable_local_qf_highlight()
  local function _call_hl()
    vim.cmd([[
      hi __SUAVE_QF_DISABLE guibg=NONE guifg=Directory
      hi __SUAVE_NO_CURSORLINE guibg=NONE guifg=NONE
    ]])
  end
  local function _disable_local_qf_highlight()
    if cursor_is_at_the_menu() then
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
---------------------------------------------------------------------------------------------------
function M.setup(opts)
  opts = opts or {}
  M.split_on_top = opts.split_on_top or true
  M.menu_height = opts.menu_height or 13
  M.store_hooks = opts.store_hooks or {
    before_mksession = {},
    after_mksession = {},
  }
  M.restore_hooks = opts.restore_hooks or {
    before_source = {},
    after_source = {},
  }

  disable_local_qf_highlight()
end


function M.folder_or_file_is_there(target_path)
  if not target_path then
    target_path = get_project_suave_path()
  end
  local yes, _, code = os.rename(target_path, target_path)
  return yes or (code == 13)
end


function M.toggle_menu()
  -- hint the user whether the current dir is suave root.
  if not M.folder_or_file_is_there() then
    print("Suave: Please create a hidden folder `.suave/` at your project root first!")
    return
  end

  if the_menu_is_open() then vim.cmd('ccl') return end

  print("Suave: You're ready to suave!")

  -- open a qflist window at the top.
  if the_menu_did_build() then
    refresh_the_menu()
    switch_to_the_menu()
    vim.cmd('top copen ' .. M.menu_height)
  end
end


function M.store_session(auto)
  if not M.folder_or_file_is_there() then return end

  if not auto and not cursor_is_at_the_menu() then
    print("Suave: Please move your cursor to the menu window to store session!")
    return
  end

  if not auto or the_menu_is_open() then M.toggle_menu() end

  -- run pre-store-hooks
  if M.store_hooks.before_mksession ~= nil then
    for _, hook in ipairs(M.store_hooks.before_mksession) do
      if type(hook) == 'function' then hook() end
    end
  end

  -- deal with auto case
  if auto then -- just overwrite the default
    vim.cmd('mksession! ' .. get_project_suave_path() .. '/default.vim')
  else
    local input = vim.fn.input('Enter a name for the current session: ')
    if input == '' or input:match('^%s+$') then -- nothing added.
      print('cancelled.')
      return
    end
    -- TODO: confirm overwrite on name repeat.
    vim.cmd('mksession! ' .. get_project_suave_path() .. '/' .. input .. '.vim')

    -- TODO: get & save note from user.
  end

  -- run post-store-hooks
  if M.store_hooks.after_mksession ~= nil then
    for _, cb in ipairs(M.store_hooks.after_mksession) do
      if type(cb) then cb() end
    end
  end

  -- restore the menu.
  if not auto then M.toggle_menu() end
end


function M.restore_session(auto)
  if not M.folder_or_file_is_there() then return end

  if not auto and not cursor_is_at_the_menu() then
    print("Suave: Please move your cursor to the menu window to restore session!")
    return
  end

  -- run pre-restore-hooks
  if M.restore_hooks.before_source ~= nil then
    for _, hook in ipairs(M.restore_hooks.before_source) do
      if type(hook) == 'function' then hook() end
    end
  end

  -- deal with auto case
  if auto then -- just overwrite the default
    vim.cmd('silent! source ' .. get_project_suave_path() .. '/default.vim')
  else
    local items = vim.fn.getqflist({ items=0 }).items
    local idx = vim.fn.line('.')
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(items[idx].bufnr), ':t')
    M.toggle_menu() -- can close the menu upon idx get.

    vim.cmd('silent! source ' .. get_project_suave_path() .. '/' .. fname)
  end

  -- run post-restore-hooks
  if M.restore_hooks.after_source ~= nil then
    for _, hook in ipairs(M.restore_hooks.after_source) do
      if type(hook) == 'function' then hook() end
    end
  end
end


return M
