#!/bin/bash

# Get the full directory path of the script
SCRIPT_DIR=$(dirname "$(realpath "$0")")

# Get the full directory path of the parent directory
PARENT_DIR=$(dirname "$SCRIPT_DIR")

PROJECTS_DIR=$PARENT_DIR/projects

SCRIPT_NAME="cleanup.sh"

for dir in "$PROJECTS_DIR"/*/; do
	if [ -d "$dir" ]; then
		echo "Checking directory: $dir"

		SCRIPT_PATH="${dir}${SCRIPT_NAME}"

		if [ -f "$SCRIPT_PATH" ] && [ -x "$SCRIPT_PATH" ]; then
			echo "Exuecuting..."
			"$SCRIPT_PATH"
		else
			echo "No executable $(bind) script found in ${dir}, skipping..."
		fi
	fi
done
