#!/bin/bash

# # for managing versions, nice to have for elixir and etc
# brew install asdf

# XSL-FO print formatter for making PDF or PS documents
# https://xmlgraphics.apache.org/fop/index.html
brew install fop

# Install LLVM
brew install llvm

# install openjdk
brew install openjdk
# For the system Java wrappers to find this JDK, symlink it with
sudo ln -sfn /opt/homebrew/opt/openjdk/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk.jdk
