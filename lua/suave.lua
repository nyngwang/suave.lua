local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local NOREF_NOERR = { noremap = true, silent = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }
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
-- to store session:
--   one can only restore session when the cursor is hover on the menu.
--
--   should check the `.suave` has been inited.
--
--   two paths:
--   autocmd store: this is done via autocmd again.
--     we always overwrite the the deafult session
--
--   manual soter: this is doen after we have prompt something to uesrs.
--     we just call that thing to save session
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

local function cursor_is_not_at_the_qflist()
  if vim.bo.buftype ~= 'quickfix'
    or vim.fn.getqflist({ id=0 }).id ~= get_the_qflist_id() then
    return false
  end
  return true
end

local function disable_local_qf_highlight()
  vim.cmd([[
    hi __SUAVE_QF_DISABLE guibg=NONE guifg=Directory
    hi __SUAVE_NO_CURSORLINE guibg=NONE guifg=NONE
  ]])
  vim.cmd('set winhl=QuickFixLine:__SUAVE_QF_DISABLE,CursorLine:__SUAVE_NO_CURSORLINE')
end

---------------------------------------------------------------------------------------------------

function M.setup(opts)

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
  disable_local_qf_highlight()

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

  -- open a qflist window at the top.
  -- TODO: setup size via config.
  if the_qflist_did_build() then
    vim.cmd('top copen 13')
  end
end

function M.store_session(auto)
  if not suave_folder_is_there() then return end

  if not auto and cursor_is_not_at_the_qflist() then
    print("Suave: Move your cursor to the menu to store session")
    return
  end

  -- run pre-store-hooks

  -- deal with auto case
  if auto then -- just overwrite the default
    vim.cmd('mksession! ./.suave/default.vim')
  else
    local input = vim.fn.input('Enter a name for the current session: ')
    if input == '' or input:match('^%s+$') then -- nothing added.
      print('cancelled.')
      return
    end
    -- TODO: confirm overwrite on name repeat.
    vim.cmd('mksession! ./.suave/' .. input .. '.vim')
  end

  -- run post-store-hooks
end



return M
