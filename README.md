suave.lua
===


## Intro.

Suave.lua aims to become the most elegant project to help you managing your project session. :)


- It has no dependency.
  - This can avoid *many troubles*(issues sea, tricky bugs, author gone, etcetc).
- The code is very compact.
  - All existing session-management projects are just too complex.


## Manual

- To start using suave.lua, just create a `.suave/` folder at your project root. (near your `.git/`)
  - I will put all your sessions into this folder.
  - Now you can manage your session along with your project.
- The core idea is pretty simple:
  - Suave.lua has one and only one menu. (Actually, it's a quickfix list)
  - You can use the menu to checkout all sessions of your current project.
  - To execute any command I provided, you have to open the menu first.
    - if you never open the menu, you will never encounter any trouble. (beginner-friendly :))
  - That's it. This is the core.
- Addons:
  - [x] The menu can show the last-modified-timestamp of each session.
  - [ ] The command for you to add note to each session file. (Since it's a quickfix list :))
  - [ ] Show how to achieve "auto-session" by `autocmd` in README.md.


## TODO

- finish README.md
  - add DEMO
  - create `autocmd` samples.
    - handle the `default.vim` session
- be able to add one note for each session
- be able to change note for each session


