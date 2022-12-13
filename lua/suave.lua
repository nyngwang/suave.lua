local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local NOREF_NOERR = { noremap = true, silent = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }
vim.api.nvim_create_augroup('suave.lua', { clear = true })
---------------------------------------------------------------------------------------------------
local M = {}
local FOLDER_NAME = '.suave'

---------------------------------------------------------------------------------------------------
-- to restore session:
--   one can only restore session when the cursor is hover on the menu.
--
--   should check the `.suave` has been inited. (check default)
--
--   two paths:
--   autocmd restore: this is done automatically via auto coommand
--     the autocmd will try to restore the session with name default
--
--   manual restore: this is done after they chose one from non-deafult
--     maby i dont need to ehcke anything ehrer since it mujst have been done when collectign menu
--
-- to prompt something to user:
--
--   to specify session name (check repeat)
--   to specify note about this session (optional)
--
-- to list all sessoin of current project:
--
--   upon selection, should duplicate that session and rename it to default.
--
-- 
-- to make use of autocmd for storing/restoring the `default` session.
--
-- 
---------------------------------------------------------------------------------------------------
local function suave_folder_is_there()
  local yes, _, code = os.rename(FOLDER_NAME, FOLDER_NAME)
  return yes or (code == 13)
end

local function total_qflists()
  return vim.fn.getqflist({ nr='$' }).nr
end

local function get_the_qflist_id()
  for i = 1, total_qflists() do
    if vim.fn.getqflist({ nr=i, title=0 }).title == FOLDER_NAME
      then return vim.fn.getqflist({ nr=i, id=0 }).id end
  end
  local z_on_s = vim.fn.setqflist({}, ' ', { nr='$', title=FOLDER_NAME })
  if z_on_s ~= 0 then
    print('Suave: Failed to create suave list!')
    return nil
  end
  return get_the_qflist_id()
end

local function the_qflist_did_build()
  return get_the_qflist_id()
end

local function get_the_qflist_winid()
  local qflist_id = get_the_qflist_id()
  if not qflist_id then return nil end
  local winid = vim.fn.getqflist({ id=qflist_id, winid=0 }).winid
  return winid > 0 and winid or nil
end

local function the_qflist_is_open()
  return get_the_qflist_winid()
end

local function cursor_is_at_the_qflist()
  if get_the_qflist_winid() == vim.api.nvim_get_current_win() then return true end
  return false
end

local function _disable_local_qf_highlight()
  if cursor_is_at_the_qflist() then
    vim.cmd([[
      hi __SUAVE_QF_DISABLE guibg=NONE guifg=Directory
      hi __SUAVE_NO_CURSORLINE guibg=NONE guifg=NONE
    ]])
    vim.cmd('set winhl=QuickFixLine:__SUAVE_QF_DISABLE,CursorLine:__SUAVE_NO_CURSORLINE')
  end
end

local function disable_local_qf_highlight()
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

local function _refresh_the_qflist()
  -- prepare items by browsing .suave/.
  local items = {}
  for dir in io.popen([[ find .suave -name '*.vim' ]]):lines() do
    items[#items+1] = {
      filename = vim.fn.fnamemodify(dir, ':t'),
      lnum = tonumber(string.sub(io.popen([[ stat -f %Sm -t %Y%m%d%H%M ]] .. dir):read(), 3, 10)), -- timestamp
      -- TODO: should maintain a mapping file to store users' note on each session.
      text = '',
    }
  end
  -- populate those items
  vim.fn.setqflist({}, 'r', {
    id = get_the_qflist_id(),
    items = items,
  })
end

function M.toggle_menu()
  -- hint the user whether the current dir is suave root.
  if not suave_folder_is_there() then
    -- TODO: hint users to do init.
    print("Suave: You haven't init suave!")
    return
  end

  if the_qflist_is_open() then vim.cmd('ccl') return end

  print("Suave: You're ready to suave!")

  _refresh_the_qflist()

  -- open a qflist window at the top.
  -- TODO: setup size via config.
  if the_qflist_did_build() then
    vim.cmd('top copen ' .. M.menu_height)
  end
end

function M.store_session(auto)
  if not suave_folder_is_there() then return end

  if not auto and not cursor_is_at_the_qflist() then
    print("Suave: Move your cursor to the menu to store session")
    return
  end

  -- should temp.ly close the menu.
  if not auto then M.toggle_menu() end

  -- run pre-store-hooks
  if M.store_hooks.before_mksession ~= nil then
    for _, hook in ipairs(M.store_hooks.before_mksession) do
      if type(hook) == 'function' then hook() end
    end
  end

  -- deal with auto case
  if auto then -- just overwrite the default
    vim.cmd('mksession! ./' .. FOLDER_NAME .. '/default.vim')
  else
    local input = vim.fn.input('Enter a name for the current session: ')
    if input == '' or input:match('^%s+$') then -- nothing added.
      print('cancelled.')
      return
    end
    -- TODO: confirm overwrite on name repeat.
    vim.cmd('mksession! ./' .. FOLDER_NAME .. '/' .. input .. '.vim')
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



return M
