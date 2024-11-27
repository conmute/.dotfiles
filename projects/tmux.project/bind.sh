#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# yazi link
rm -rf ~/.tmux.conf
ln -s $PROJECT_DIR/dotfiles/.tmux.conf ~/.tmux.conf
rm -rf ~/.tmux
ln -s $PROJECT_DIR/dotfiles/.tmux ~/.tmux

