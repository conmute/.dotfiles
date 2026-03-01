#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# hk-action command → ~/bin/
mkdir -p ~/bin
ln -sf "$PROJECT_DIR/bin/hk-action" ~/bin/hk-action

# sounds → ~/.local/share/gamify/sounds/
mkdir -p ~/.local/share/gamify
rm -rf ~/.local/share/gamify/sounds
ln -s "$PROJECT_DIR/sounds" ~/.local/share/gamify/sounds

echo "gamify.project bound: hk-action → ~/bin/, sounds → ~/.local/share/gamify/sounds/"
