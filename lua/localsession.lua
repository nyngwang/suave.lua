local NOREF_NOERR_TRUNC = { noremap = true, silent = true, nowait = true }
local NOREF_NOERR = { noremap = true, silent = true }
local EXPR_NOREF_NOERR_TRUNC = { expr = true, noremap = true, silent = true, nowait = true }
---------------------------------------------------------------------------------------------------
local M = {}
local FOLDER_NAME = '.suave'

---------------------------------------------------------------------------------------------------
-- mabye there shoudl be a main file, jsut like package.json
-- when the session is saved, it's inside .suave/
--   it's a good idea to save multiple session there
--   how about gamify it? Create a beautiful menu with fzf-lua so one can choice which...
--     ...session to recover from
--   / if so should alos have a convenient way to delete selected session (should do some check)
--     ...actually it's no harm to keep a lot of session file there, since we always save to deafult
--
-- to restore session:
--   if we're currnetly on a suave root, then we can restore session. get out otherwise
--     so I need to chekc for the folder .suave/ exisit
--
--   if exist, we can restore session
--
--     two paths:
--     autocmd restore: this is done automatically via auto coommand
--       the autocmd will try to restore the session with name default
--
--     manual restore: this is done after they chose one from non-deafult
--       maby i dont need to ehcke anything ehrer since it mujst have been done when collectign menu
--
-- to store session:
--
--   again if we're not currenlyt on a suvae root, then get out :)
--
--   if exist, we can store session
--
--     two paths:
--     autocmd store: this is done via autocmd again.
--       we always overwrite the the deafult session
--
--     manual soter: this is doen after we have prompt something to uesrs.
--       we just call that thing to save session
--
-- to prompt something to user:
--
--   ok, os here is the idae: the user csan only save a new session wehn they open...
--     ...the list of all session exlucding the default one.
--     and this way we jsut need to creat keymap/command just for this buffer/window
--
--   after repeat ehcke just store the session in .suave/
--
-- to list all sessoin of current project.
--
--   well this is also the wya a user cehck that wehteht they're a suave root.
--   
--   show the menu anyway, but it shoudl hint the user if .suave not exist.
--
--   if the suvae fodler exist then show all current existing sessoin
--   (how about adding note to each sesion?)
--
--   upon selection, should duplicate that sesion and rename it to default
--
--
--
-- 
-- next we will need to make use of autocmd so that storing/restoring is done automatically
--   there should be a default session withi is always recording,
--   then the user can save a session at any point wtih a readable name (and descrioption)
--
-- 
---------------------------------------------------------------------------------------------------
-- TODO: have a better naem
local function suave_folder_is_there()
  local yes, _, code = os.rename(FOLDER_NAME, FOLDER_NAME)
  return yes or (code == 13)
end

function M.setup(opts)

end

function M.restore(se_file)

end



return M
