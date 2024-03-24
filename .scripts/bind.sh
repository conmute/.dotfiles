#!/bin/bash

# Get the full directory path of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Get the full directory path of the parent directory
PARENT_DIR=$(dirname "$SCRIPT_DIR")

# setup nvim
rm -rf ~/.config/nvim
ln -s $PARENT_DIR/.config/nvim ~/.config/nvim

# setup git config
rm ~/.gitignore
rm ~/.gitconfig
rm ~/.gitignore_global
ln -s $PARENT_DIR/.gitconfig ~/.gitconfig
ln -s $PARENT_DIR/.gitignore ~/.gitignore
ln -s $PARENT_DIR/.gitignore_global ~/.gitignore_global

# User .env config
mv ~/.env{,.bak}
ln -s $PARENT_DIR/.env ~/.env

# .dot_profile
echo "source \"$PARENT_DIR/.dot_profile\"" >> ~/.zshrc
