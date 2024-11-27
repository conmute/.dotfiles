#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

rm -rf ~/.config/fish
ln -s $PROJECT_DIR/fish ~/.config/fish

