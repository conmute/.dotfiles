#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# setup nvim
rm -rf ~/.config/nvim
ln -s $PROJECT_DIR/nvim ~/.config/nvim
