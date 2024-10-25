#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_yarn() {
  if yarn --version >/dev/null 2>&1; then
    print_info "Yarn is already installed ..."
  else
    print_info "Installing Yarn package ..."

    if ! npm --version >/dev/null 2>&1 || ! node --version >/dev/null 2>&1; then
      handle_error "Node.js must be installed before installing Yarn"
    fi

    # shellcheck source=/dev/null
    source "${HOME}/.bashrc" || handle_error "Failed to source .bashrc"
    NVM_DIR="$HOME/.nvm"
    export NVM_DIR
    if [[ -s "$NVM_DIR/nvm.sh" ]]; then
      # shellcheck source=/dev/null
      source "$NVM_DIR/nvm.sh" || handle_error "Failed to source NVM script"
    fi
    if [[ -s "$NVM_DIR/bash_completion" ]]; then
      # shellcheck source=/dev/null
      source "$NVM_DIR/bash_completion" || handle_error "Failed to source NVM bash completion script"
    fi

    # Install Yarn globally using npm
    npm install --global yarn >/dev/null 2>&1 || handle_error "Failed to install Yarn package"

    print_success "Yarn installed successfully."
  fi
}

install_yarn
