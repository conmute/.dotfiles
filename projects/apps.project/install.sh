#!/bin/bash

# # Always check what you're installing first
# brew info --cask <package>
#
# # Look at the download URL
# brew cat --cask <package>
# brew cat --cask <package> | grep -A 2 "url"
#
# # Keep Homebrew updated
# brew update

# I use a lot for personal communication
brew install --cask telegram
brew install --cask discord

# prefered term
brew install iterm2

# to hold git project nice and clean
brew install ghq

# to display current folder in tree
brew install lsd

# I am listening to spotify
brew install --cask spotify

# I am using local llms...
brew install ollama
brew install ollama-app

# for development i use..
brew install --cask insomnia
