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

source $HOME/.env

# fzf
# to completely uninstall, use /usr/local/opt/fzf/uninstall
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# export FZF_DEFAULT_COMMAND='find . \( -name node_modules -o -name .git \) -prune -o -print'
# export FZF_DEFAULT_COMMAND='fd --type f --color=always --exclude .git --ignore-file ~/.gitignore'
export FZF_DEFAULT_COMMAND='fd --type f --exclude .git --ignore-file ~/.gitignore'
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND

export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh" # This loads nvm

# # Check if .nvmrc file exists
# test -f .nvmrc && nvm use

# Obsidian

## This command to automatically publish things outside! To be configured…
## Should be in `bin/obsidian`...
# alias ou='cd $HOME/notion-obsidian-sync-zazencodes && node batchUpload.js --lastmod-days-window 5'
#

# TODO: test if asdf is installed
# TODO: add to basic config to preinstall asdf, would be even btter
# asdf for erlang/elixir version management
. /usr/local/opt/asdf/libexec/asdf.sh

exec fish
