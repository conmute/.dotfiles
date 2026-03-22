set fish_greeting ""

#set -gx TERM xterm-256color

# theme
set -g theme_color_scheme terminal-dark
set -g fish_prompt_pwd_dir_length 1
set -g theme_display_user yes
set -g theme_hide_hostname no
set -g theme_hostname always

# aliases
alias ls "ls -p -G"
alias la "ls -A"
alias ll "ls -l"
alias lla "ll -A"
alias g git
alias oo 'cd $OBSIDIAN_ROOT'
alias ox 'vim "$OBSIDIAN_ROOT/11 INBOX/*.md"'

command -qv nvim && alias vim nvim

# Gamified claude — play level-start sound on launch
function claude --wraps=claude
    gamify play app-start &
    command claude $argv
end

# Gamified shell — random HK combat sound on every command (interactive only)
function __gamify_preexec --on-event fish_preexec
    test -n "$argv[1]" || return
    killall afplay &>/dev/null
    gamify play quick-action &>/dev/null &
    disown
end

set -gx EDITOR nvim

set -gx PATH bin $PATH
set -gx PATH ~/bin $PATH
set -gx PATH ~/.local/bin $PATH

# NodeJS
set -gx PATH node_modules/.bin $PATH

# Go
set -g GOPATH $HOME/go
set -gx PATH $GOPATH/bin $PATH

switch (uname)
    case Darwin
        source (dirname (status --current-filename))/config-osx.fish
        # case Linux
        #     source (dirname (status --current-filename))/config-linux.fish
        # case '*'
        #     source (dirname (status --current-filename))/config-windows.fish
end

set LOCAL_CONFIG (dirname (status --current-filename))/config-local.fish
if test -f $LOCAL_CONFIG
    source $LOCAL_CONFIG
end

# @see: https://asdf-vm.com/guide/getting-started.html
# ASDF configuration code
if test -z $ASDF_DATA_DIR
    set _asdf_shims "$HOME/.asdf/shims"
else
    set _asdf_shims "$ASDF_DATA_DIR/shims"
end

# Do not use fish_add_path (added in Fish 3.2) because it
# potentially changes the order of items in PATH
if not contains $_asdf_shims $PATH
    set -gx --prepend PATH $_asdf_shims
end
set --erase _asdf_shims

# tmux-spire CLI (only inside tmux)
if set -q TMUX; and set -q SPIRE_BIN; and not contains $SPIRE_BIN $PATH
    set -gx --prepend PATH $SPIRE_BIN
end
