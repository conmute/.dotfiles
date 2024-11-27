#!/bin/bash

# Get the full directory path of the script
PROJECT_DIR=$(dirname "$(realpath "$0")")

# make bin accessible
mkdir -p ~/bin
ln -s $PROJECT_DIR/gitscripts/github_download_folder ~/bin/github_download_folder

