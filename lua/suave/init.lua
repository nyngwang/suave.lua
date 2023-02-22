local P = require('suave.utils.path')
local Q = require('suave.utils.qflist')
local J = require('suave.utils.json')
local A = require('suave.utils.autocmd')
local helpers = require('suave.helpers')
local M = {}
vim.api.nvim_create_augroup('suave.lua', { clear = true })
---------------------------------------------------------------------------------------------------
function M.setup(opts)
  if not opts then opts = {} end

  M.menu_height = opts.menu_height or 13
  M.store_hooks = opts.store_hooks or { before_mksession = {}, after_mksession = {} }
    if type(M.store_hooks.before_mksession) ~= 'table' then M.store_hooks.before_mksession = {} end
    if type(M.store_hooks.after_mksession) ~= 'table' then M.store_hooks.after_mksession = {} end
    helpers.add_method_append(M.store_hooks.before_mksession)
    helpers.add_method_append(M.store_hooks.after_mksession)
  M.restore_hooks = opts.restore_hooks or { before_source = {}, after_source = {} }
    if type(M.restore_hooks.before_source) ~= 'table' then M.restore_hooks.before_source = {} end
    if type(M.restore_hooks.after_source) ~= 'table' then M.restore_hooks.after_source = {} end
    helpers.add_method_append(M.restore_hooks.before_source)
    helpers.add_method_append(M.restore_hooks.after_source)
  M.autocmds = opts.autocmds or { auto_save = nil, switcher_on_cd = nil }
    if type(M.autocmds) ~= 'table' then M.autocmds = {} end
    if type(M.autocmds.auto_save) ~= 'table' then M.autocmds.auto_save = {} end
      if type(M.autocmds.auto_save.enabled) ~= 'boolean' then M.autocmds.auto_save.enabled = false end
      if type(M.autocmds.auto_save.exclude_filetypes) ~= 'table' then M.autocmds.auto_save.exclude_filetypes = {} end
    if type(M.autocmds.switcher_on_cd) ~= 'table' then M.autocmds.switcher_on_cd = {} end
      if type(M.autocmds.switcher_on_cd.enabled) ~= 'boolean' then M.autocmds.switcher_on_cd.enabled = true end


  Q.disable_local_qf_highlight()
  A.create_autocmds(M.autocmds)
end


function M.toggle_menu()
  if not P.folder_or_file_is_there() then
    print("Suave: Please create a hidden folder `.suave/` at your project root first!")
    return
  end

  if Q.the_menu_is_open() then vim.cmd('ccl') return end

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

  if Q.the_menu_is_open() then M.toggle_menu() end

  local succeeded, data = unpack(J.get_or_create_project_file_data())

  -- store_hooks - before mksession.
  for key, hook in pairs(M.store_hooks.before_mksession) do
    if type(key) == 'number' and type(hook) == 'function' then hook(data) end
  end

  if auto then
    vim.cmd('mksession! ' .. P.get_project_session_folder_path() .. '/default.vim')
  else
    local input = vim.fn.input('Enter a name for the current session: ')
    if input == '' or input:match('^%s+$') then -- nothing added.
      print("cancelled.")
      return
    end
    -- TODO: confirm overwrite on name repeat.
    vim.cmd('mksession! ' .. P.get_project_session_folder_path() .. '/' .. input .. '.vim')
  end

  -- store_hooks - after mksession.
  for key, hook in pairs(M.store_hooks.after_mksession) do
    if type(key) == 'number' and type(hook) == 'function' then hook(data) end
  end

  if succeeded and type(data) == 'table' then
    J.write_to_project_json(data)
  end

  -- since open the menu is required to store session.
  if not auto then M.toggle_menu() end
end


function M.restore_session(auto)
  if not P.folder_or_file_is_there() then return end
  print("Suave: Found the `.suave/` folder!")

  if not auto and not Q.cursor_is_at_the_menu() then
    print("Suave: Please move your cursor to the menu window to restore session!")
    return
  end

  local _, data = unpack(J.get_or_create_project_file_data())

  -- restore_hooks - before source.
  for key, hook in pairs(M.restore_hooks.before_source) do
    if type(key) == 'number' and type(hook) == 'function' then hook() end
  end

  if auto then
    vim.cmd('silent! source ' .. P.get_project_session_folder_path() .. '/default.vim')
  else
    local items = vim.fn.getqflist({ items=0 }).items
    local idx = vim.fn.line('.')
    local fname = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(items[idx].bufnr), ':t')
    M.toggle_menu() -- can close the menu upon idx get.

    vim.cmd('silent! source ' .. P.get_project_session_folder_path() .. '/' .. fname)
  end

  -- restore_hooks - after source.
  for key, hook in pairs(M.restore_hooks.after_source) do
    if type(key) == 'number' and type(hook) == 'function' then hook(data) end
  end
end


return M
