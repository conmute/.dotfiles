#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

files=(
	".gitconfig"
	".gitignore"
	".gitignore_global"
)

for file in "${files[@]}"; do
	echo "Processing file: $file"
	rm -rf ~/$file
	ln -s $PROJECT_DIR/dotfiles/$file ~/$file
done
