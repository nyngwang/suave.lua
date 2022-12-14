vim.api.nvim_create_augroup('suave.lua', { clear = true })
---------------------------------------------------------------------------------------------------
local M = {}
local FOLDER_NAME = '.suave'

---------------------------------------------------------------------------------------------------
local function get_project_suave_path()
  return vim.fn.getcwd(-1, -1) .. '/' .. FOLDER_NAME
end


function M.suave_folder_is_there()
  -- assume users won't call `cd` when they want to change the path for each new tab created.
  local project_suave_path = get_project_suave_path()
  local yes, _, code = os.rename(project_suave_path, project_suave_path)
  return yes or (code == 13)
end

local function total_qflists()
  return vim.fn.getqflist({ nr='$' }).nr
end

local function get_menu_id()
  for i = 1, total_qflists() do
    if vim.fn.getqflist({ nr=i, title=0 }).title == FOLDER_NAME
      then return vim.fn.getqflist({ nr=i, id=0 }).id end
  end
  local z_on_s = vim.fn.setqflist({}, ' ', { nr='$', title=FOLDER_NAME })
  if z_on_s ~= 0 then
    print('Suave: Failed to create suave menu!')
    return nil
  end
  return get_menu_id()
end

local function the_menu_did_build()
  return get_menu_id()
end

local function get_the_menu_winid()
  local id = get_menu_id()
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
end

local function _refresh_the_menu()
  -- prepare items by browsing .suave/.
  local items = {}
  for dir in io.popen([[ find ]] .. get_project_suave_path() .. [[ -name '*.vim' ]]):lines() do
    items[#items+1] = {
      filename = vim.fn.fnamemodify(dir, ':t'),
      lnum = tonumber(string.sub(io.popen([[ stat -f %Sm -t %Y%m%d%H%M ]] .. dir):read(), 3, 10)), -- timestamp
      -- TODO: should maintain a mapping file to store users' note on each session.
      text = '',
    }
  end
  -- populate those items
  vim.fn.setqflist({}, 'r', {
    id = get_menu_id(),
    items = items,
  })
end

function M.toggle_menu()
  -- hint the user whether the current dir is suave root.
  if not M.suave_folder_is_there() then
    -- TODO: hint users to do init.
    print("Suave: You haven't init suave!")
    return
  end

  if the_menu_is_open() then vim.cmd('ccl') return end

  print("Suave: You're ready to suave!")

  _refresh_the_menu()

  -- open a qflist window at the top.
  -- TODO: setup size via config.
  if the_menu_did_build() then
    vim.cmd('top copen ' .. M.menu_height)
  end
end

function M.store_session(auto)
  if not M.suave_folder_is_there() then return end

  if not auto and not cursor_is_at_the_menu() then
    print("Suave: Move your cursor to the menu to store session")
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
  if not M.suave_folder_is_there() then return end

  if not auto and not cursor_is_at_the_menu() then
    print("Suave: Move your cursor to the menu to restore session")
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
    local items = vim.fn.getqflist({ items = 0 }).items
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

---------------------------------------------------------------------------------------------------
local function disable_local_qf_highlight()
  local function _disable_local_qf_highlight()
    if cursor_is_at_the_menu() then
      vim.cmd([[
        hi __SUAVE_QF_DISABLE guibg=NONE guifg=Directory
        hi __SUAVE_NO_CURSORLINE guibg=NONE guifg=NONE
      ]])
      vim.cmd('set winhl=QuickFixLine:__SUAVE_QF_DISABLE,CursorLine:__SUAVE_NO_CURSORLINE')
    end
  end
  vim.api.nvim_create_autocmd({ 'BufWinEnter' }, {
    group = 'suave.lua',
    pattern = 'quickfix',
    callback = function () _disable_local_qf_highlight() end
  })
  vim.api.nvim_create_autocmd({ 'BufEnter' }, {
    group = 'suave.lua',
    pattern = '*', -- match against qf name.
    callback = function () _disable_local_qf_highlight() end
  })
end
disable_local_qf_highlight()


return M
