#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# gamify command → ~/bin/
mkdir -p ~/bin
ln -sf "$PROJECT_DIR/bin/gamify" ~/bin/gamify

# sounds → ~/.local/share/gamify/sounds/
mkdir -p ~/.local/share/gamify
rm -rf ~/.local/share/gamify/sounds
ln -s "$PROJECT_DIR/sounds" ~/.local/share/gamify/sounds

# git-templates for new repos (post-commit sound)
mkdir -p ~/.git-templates/hooks
ln -sf "$PROJECT_DIR/hooks/post-commit" ~/.git-templates/hooks/post-commit

echo "gamify.project bound: gamify → ~/bin/, sounds → ~/.local/share/gamify/sounds/, git-templates → ~/.git-templates/"
