#!/bin/bash

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

# Check if .nvmrc file exists
test -f .nvmrc && nvm use
