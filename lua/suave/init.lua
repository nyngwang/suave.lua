local P = require('suave.utils.path')
local Q = require('suave.utils.qflist')
local J = require('suave.utils.json')
local M = {}
vim.api.nvim_create_augroup('suave.lua', { clear = true })
---------------------------------------------------------------------------------------------------
function M.setup(opts)
  if not opts then opts = {} end

  M.menu_height = opts.menu_height or 13
  M.store_hooks = opts.store_hooks or {
    before_mksession = {},
    after_mksession = {},
  }
  M.restore_hooks = opts.restore_hooks or {
    before_source = {},
    after_source = {},
  }

  Q.disable_local_qf_highlight()
end


function M.toggle_menu()
  -- hint the user whether the current dir is suave root.
  if not P.folder_or_file_is_there() then
    print("Suave: Please create a hidden folder `.suave/` at your project root first!")
    return
  end

  if Q.the_menu_is_open() then vim.cmd('ccl') return end

  print("Suave: You're ready to suave!")

  -- open a qflist window at the top.
  if Q.the_menu_did_build() then
    Q.refresh_the_menu()
    Q.switch_to_the_menu()
    vim.cmd('top copen ' .. M.menu_height)
  end
end


function M.store_session(auto)
  if not P.folder_or_file_is_there() then return end

  if not auto and not Q.cursor_is_at_the_menu() then
    print("Suave: Please move your cursor to the menu window to store session!")
    return
  end

  if not auto or Q.the_menu_is_open() then M.toggle_menu() end

  -- prepare store project data.
  local succeed, data = J.get_or_create_project_file_data()

  -- run pre-store-hooks.
  -- TODO: should use type() == 'table' instead
  -- TODO: should use pairs instead
  if M.store_hooks.before_mksession ~= nil then
    for _, hook in ipairs(M.store_hooks.before_mksession) do
      if type(hook) == 'function' then hook(data) end
    end
  end

  -- deal with auto case.
  if auto then -- just overwrite the default.
    vim.cmd('mksession! ' .. P.get_project_session_folder_path() .. '/default.vim')
  else
    local input = vim.fn.input('Enter a name for the current session: ')
    if input == '' or input:match('^%s+$') then -- nothing added.
      print('cancelled.')
      return
    end
    -- TODO: confirm overwrite on name repeat.
    vim.cmd('mksession! ' .. P.get_project_session_folder_path() .. '/' .. input .. '.vim')

    -- TODO: get & save note from user.
  end

  -- run post-store-hooks.
  if M.store_hooks.after_mksession ~= nil then
    for _, hook in ipairs(M.store_hooks.after_mksession) do
      if type(hook) == 'function' then hook(data) end
    end
  end

  -- restore project data.
  if succeed and type(data) == 'table' then
    J.write_to_project_json(data)
  end

  -- restore the menu.
  if not auto then M.toggle_menu() end
end


function M.restore_session(auto)
  if not P.folder_or_file_is_there() then return end

  if not auto and not Q.cursor_is_at_the_menu() then
    print("Suave: Please move your cursor to the menu window to restore session!")
    return
  end

  -- prepare restore project data.
  local _, data = J.get_or_create_project_file_data()

  -- run pre-restore-hooks.
  if M.restore_hooks.before_source ~= nil then
    for _, hook in ipairs(M.restore_hooks.before_source) do
      if type(hook) == 'function' then hook(data) end
    end
  end

  -- deal with auto case.
  if auto then -- just overwrite the default.
    vim.cmd('silent! source ' .. P.get_project_session_folder_path() .. '/default.vim')
  else
    local items = vim.fn.getqflist({ items=0 }).items
    local idx = vim.fn.line('.')
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(items[idx].bufnr), ':t')
    M.toggle_menu() -- can close the menu upon idx get.

    vim.cmd('silent! source ' .. P.get_project_session_folder_path() .. '/' .. fname)
  end

  -- run post-restore-hooks.
  if M.restore_hooks.after_source ~= nil then
    for _, hook in ipairs(M.restore_hooks.after_source) do
      if type(hook) == 'function' then hook(data) end
    end
  end
end


return M
