#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

files=(
	"settings.json"
	"policy-limits.json"
)

targets=(
	"$HOME/.claude"
	"$HOME/.caleb"
)

for target in "${targets[@]}"; do
	mkdir -p "$target"
	for file in "${files[@]}"; do
		echo "Binding $file -> $target/$file"
		rm -rf "$target/$file"
		ln -s "$PROJECT_DIR/dotfiles/$file" "$target/$file"
	done
done
