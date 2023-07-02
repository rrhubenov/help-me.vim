vim9script noclear

final g:help_plugins = []
const g:help_path = "~/.vim/help/"

const DEBUG = 0

# Fill help_plugins with currently installed plugins
var curr_dir = getcwd()
for f in glob("~/.vim/help/*", 0, 1)
    chdir(f)
    # Need to trim since every line is given with a newline at the end. Very bash
    # like, yes, yes
    add(g:help_plugins, trim(system("git config --get remote.origin.url")))
endfor
chdir(curr_dir)

def Debug(msg: string)
    if DEBUG
        echomsg msg
    endif
enddef

export def Add(help_name: string)
    const full_help_name = "git@github.com:" .. help_name
    const [creator, repo] = split(help_name, "/")
    const full_help_path = g:help_path .. repo

    # Check if the help_name is already in list. This check might
    # need to be more complicated so think of it as a TODO
    if index(g:help_plugins, full_help_name) >= 0
        Debug("Item " .. help_name .. " already in help list")
        call AddToRtp(full_help_path)
        return
    endif
    
    # Clone repo
    call system("git -C " .. g:help_path .. " clone " .. "git@github.com:" .. help_name)
    call add(g:help_plugins, full_help_name)
    call AddToRtp(full_help_path)
    execute "helptags " .. full_help_path
    SetupTagFileInDir(full_help_path)
    Debug("Successfully added " .. help_name)
enddef

def SetupTagFileInDir(dir: string)
    const currentFile = expand("%")

    mkdir(expand(dir) .. "/doc") 
    rename(expand(dir) .. "/tags", expand(dir) .. "/doc/tags") 
    silent execute "edit " .. expand(dir) .. "/doc/tags"

    # Substitute "\tsomething.txt\t" with "\t../something.txt\t"
    silent :%s/\v\t(.*\.txt)\t/\t\.\.\/\1\t/g
    
    silent update
    # Return to the opened file
    execute "silent edit " .. currentFile
enddef

def AddToRtp(path: string)
    Debug("adding " .. path .. " to rtp")
    execute "set rtp+=" .. path
enddef

export def Show()
    for item in g:help_plugins
        echo item
    endfor
enddef

