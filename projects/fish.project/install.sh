#!/bin/bash

brew install fish

# json preview
brew install jq
# for file searching
brew install fd
# for content searching
brew install rg
# for quick subtree navigation
brew install fzf
# historical directories navigation
brew install zoxide

echo "Follow log to finish nvm installation!"

echo "fish created a claude-work for private $ANTHROPIC_API_KEY, with a separate ~/.claude-work directory"
mkdir -p ~/.claude-work
