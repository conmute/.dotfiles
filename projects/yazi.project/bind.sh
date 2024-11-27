#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# yazi link
rm -rf ~/.config/yazi
ln -s $PROJECT_DIR/yazi ~/.config/yazi

