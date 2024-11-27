#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

files=(
	".editorconfig"
	".env.example"
	".wezterm.lua"
)

for file in "${files[@]}"; do
	echo "Processing file: $file"
	rm -rf ~/$file
	ln -s $PROJECT_DIR/dotfiles/$file ~/$file
done

# .dot_profile
echo "source \"$PROJECT_DIR/dotfiles/.zshrc_profile.sh\"" >>~/.zshrc
