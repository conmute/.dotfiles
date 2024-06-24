#!/bin/bash

# Get the full directory path of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Get the full directory path of the parent directory
PARENT_DIR=$(dirname "$SCRIPT_DIR")

# setup nvim
rm -rf ~/.config/nvim
ln -s $PARENT_DIR/.config/nvim ~/.config/nvim

rm -rf ~/.config/fish
ln -s $PARENT_DIR/.config/fish ~/.config/fish

rm -rf ~/.tmux.conf
ln -s $PARENT_DIR/.tmux.conf ~/.tmux.conf
rm -rf ~/.tmux
ln -s $PARENT_DIR/.tmux ~/.tmux

# setup obsidian new note
ln -s $PARENT_DIR/bin/obsidian/on ~/bin/on
ln -s $PARENT_DIR/bin/obsidian/og ~/bin/og

# setup git config
rm ~/.gitignore
rm ~/.gitconfig
rm ~/.gitignore_global
ln -s $PARENT_DIR/.gitconfig ~/.gitconfig
ln -s $PARENT_DIR/.gitignore ~/.gitignore
ln -s $PARENT_DIR/.gitignore_global ~/.gitignore_global

# User .env config
# mv ~/.env{,.bak}
rm ~/.env.example
ln -s $PARENT_DIR/.env.example ~/.env.example

# .dot_profile
echo "source \"$PARENT_DIR/.dot_profile.sh\"" >>~/.zshrc
