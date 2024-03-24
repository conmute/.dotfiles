#!/bin/bash

# setup nvim
rm -rf ~/.config.nvim
ln -s ~/.dotfiles/.config/nvim ~/.config/nvim

# setup git config
rm ~/.gitignore
rm ~/.gitconfig
rm ~/.gitignore_global
ln -s ~/.dotfiles/.gitconfig ~/.gitconfig
ln -s ~/.dotfiles/.gitignore ~/.gitignore
ln -s ~/.dotfiles/.gitignore_global ~/.gitignore_global
