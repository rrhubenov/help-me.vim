vim9script noclear

command HelpInstall call HelpInstall()
command HelpShow call Show()
command HelpClean call HelpClean()
command HelpSync call HelpSync()
command HelpList call List()
command -nargs=* HelpNew call New(<f-args>)

final g:help_plugins_to_install = []
const g:help_path = "~/.vim/help/"
const g:local_help_path = expand("~/.vim") .. "/help_local"
call mkdir(g:local_help_path, "p")

const DEBUG = 0

def Debug(msg: string)
    if DEBUG
        echomsg msg
    endif
enddef

export def Add(help_name: string)
    add(g:help_plugins_to_install, help_name)
enddef

def SetupTagFileInDir(dir: string)
    const currentFile = expand("%")

    mkdir(expand(dir) .. "/doc", "p") 
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

def GetAlreadyInstalled(): list<string>
    final already_installed_plugins = []
    # Fill already_installed_plugins with currently installed plugins
    var curr_dir = getcwd()
    for f in glob("~/.vim/help/*", 0, 1)
        chdir(f)
        # Need to trim since every line is given with a newline at the end. Very bashy
        var repo_name = split(trim(system("git config --get remote.origin.url")), ":")[1]

        add(already_installed_plugins, repo_name)
    endfor
    chdir(curr_dir)

    return already_installed_plugins
enddef

def HelpInstall()
    final already_installed_plugins = GetAlreadyInstalled()

    for help_name in g:help_plugins_to_install
        # const full_help_name = "git@github.com:" .. help_name
        const [creator, repo] = split(help_name, "/")
        const full_help_path = g:help_path .. repo
        # Check if the help_name is already in list. This check might
        # need to be more complicated so think of it as a TODO
        if index(already_installed_plugins, help_name) >= 0
            Debug("Item " .. help_name .. " already in help list")
            call AddToRtp(full_help_path)
            return
        endif
        
        # Clone repo
        call system("git -C " .. g:help_path .. " clone " .. "git@github.com:" .. help_name)
        #call add(g:help_plugins, full_help_name)
        call AddToRtp(full_help_path)
        execute "helptags " .. full_help_path
        call SetupTagFileInDir(full_help_path)
        call Debug("Successfully added " .. help_name)
    endfor
enddef

def HelpClean()
    final already_installed_plugins = GetAlreadyInstalled()
    
    for help_name in already_installed_plugins
        Debug("Checking " .. help_name .. " for cleaning")
        const [creator, repo] = split(help_name, "/")
        const full_help_path = g:help_path .. repo
        if index(g:help_plugins_to_install, help_name) == -1
            call Debug("Removing " .. full_help_path)
            call delete(expand(full_help_path), "rf")
        endif
    endfor
enddef

def HelpSync()
    call HelpClean()
    call HelpInstall()
enddef

def New(project: string, subject: string)
    # Create a new directory 'project' in help dir if
    # it doesn't exist
    # Create new .txt help file in the dir if it
    # doesn't exit
    # Enable editing the help file
    
    call mkdir(g:local_help_path .. "/" .. project, "p")

    exe "edit " ..  expand(g:local_help_path) .. "/" .. project .. "/" .. subject .. ".txt"
    setlocal filetype=help
    setlocal modifiable

    #autocmd BufWritePost 

enddef

# Show available help projects/subjects
def List()
    var help_files = glob(g:help_path .. "*/*.txt", 0, 1)
    vnew
    setlocal buftype=nofile
    setlocal bufhidden=hide
    setlocal noswapfile

    append(0, help_files)
    setlocal readonly
    setlocal nomodifiable 
    set filetype=help

    nnoremap <buffer> <CR> gf
enddef

export def Show()
    for item in g:help_plugins_to_install
        echo item
    endfor
enddef
