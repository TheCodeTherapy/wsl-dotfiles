#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_node() {
  if [[ -f $NVMDIR/nvm.sh ]]; then
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

    if node --version >/dev/null 2>&1; then
      print_info "Node.js is already installed ..."
    else
      print_info "Installing the latest LTS version of Node.js ..."

      nvm install --lts >/dev/null 2>&1 || handle_error "Failed to install the latest LTS version of Node.js"

      print_success "Node.js and npm installed successfully."
    fi
  else
    handle_error "NVM is not installed. Please install NVM first."
  fi
}

install_node
