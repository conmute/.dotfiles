#!/bin/bash

export LANG="en_US.UTF-8"
LC_COLLATE="en_US.UTF-8"
LC_CTYPE="en_US.UTF-8"
LC_MESSAGES="en_US.UTF-8"
LC_MONETARY="en_US.UTF-8"
LC_NUMERIC="en_US.UTF-8"
LC_TIME="en_US.UTF-8"
LC_ALL="en_US.UTF-8"

export PATH=~/bin:$PATH

export PATH="/opt/homebrew/opt/openjdk/bin:$PATH"

# # For compilers to find openjdk you may need to set:
# export CPPFLAGS="-I/opt/homebrew/opt/openjdk/include"

export PATH="/opt/homebrew/opt/llvm/bin:$PATH"

# export PATH="/usr/local/bin/dump_zsh_state:$PATH"
export PATH="/opt/homebrew/bin:$PATH"

# # For compilers to find llvm you may need to set:
# export LDFLAGS="-L/opt/homebrew/opt/llvm/lib"
# export CPPFLAGS="-I/opt/homebrew/opt/llvm/include"

source $HOME/.env

# fzf
# to completely uninstall, use /usr/local/opt/fzf/uninstall
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# export FZF_DEFAULT_COMMAND='find n . \( -name node_modules -o -name .git \) -prune -o -print'
# export FZF_DEFAULT_COMMAND='fd --type f --color=always --exclude .git --ignore-file ~/.gitignore'
export FZF_DEFAULT_COMMAND='fd --type f --exclude .git --ignore-file ~/.gitignore'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

# nvm is already loaded in .zshrc — don't load it again here

# # Check if .nvmrc file exists
# test -f .nvmrc && nvm use

# Obsidian

## This command to automatically publish things outside! To be configured…
## Should be in `bin/obsidian`...
# alias ou='cd $HOME/notion-obsidian-sync-zazencodes && node batchUpload.js --lastmod-days-window 5'
#

# # TODO: on install on new machine, it didnt work ;(
# # TODO: test if asdf is installed
# # TODO: add to basic config to preinstall asdf, would be even btter
# # asdf for erlang/elixir version management
# . /usr/local/opt/asdf/libexec/asdf.sh

# Launch fish for non-tmux terminals (Cursor, VS Code, etc.)
# tmux launches fish directly via default-shell, so skip there
if [ -z "$TMUX" ]; then
  exec fish
fi
