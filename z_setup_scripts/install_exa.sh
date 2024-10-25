#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_exa() {
  if [[ -f $HOME/.cargo/bin/exa ]]; then
    print_info "Exa is already installed ..."
  else
    print_info "Installing Exa ..."

    # shellcheck source=/dev/null
    source "$HOME/.cargo/env" || handle_error "Failed to source Cargo environment"

    cargo install exa >/dev/null 2>&1 || handle_error "Failed to install Exa"

    print_success "Exa installed successfully."
  fi
}

install_exa
