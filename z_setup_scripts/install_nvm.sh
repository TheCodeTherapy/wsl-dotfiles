#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_nvm() {
  if [[ -f $NVMDIR/nvm.sh ]]; then
    print_info "NVM is already installed ..."
  else
    print_info "Installing NVM ..."

    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash >/dev/null 2>&1 ||
      handle_error "Failed to install NVM"

    # shellcheck source=/dev/null
    source "${ME}/.bashrc" || handle_error "Failed to source .bashrc"

    NVM_DIR="$HOME/.nvm"
    export NVM_DIR
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
    [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

    nvm --version >/dev/null 2>&1 ||
      handle_error "Failed to verify NVM installation"

    print_success "NVM installed successfully."
  fi
}

install_nvm
