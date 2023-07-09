vim9script noclear
# Vim plugin manager specifically for help files
# Expects that a help plugin is hosted on github
# Last Change: 30.06.2023
# Mainainer:   Radoslav Hubenov <rrhubenov@gmail.com>
# License:     This file is placed in the public domain.

if exists("g:loaded_help_me")
    finish
endif
g:loaded_help_me = 1

if !isdirectory("~/.vim/help")
    mkdir($HOME .. "/.vim/help", "p")
endif 





