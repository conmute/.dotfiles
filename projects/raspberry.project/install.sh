#!/bin/bash

# Install Ansible on macOS for provisioning the Raspberry Pi
brew install ansible

# Install required Ansible collections
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ansible-galaxy collection install -r "$SCRIPT_DIR/requirements.yml"
