#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_fd() {
  if fd --version >/dev/null 2>&1; then
    print_info "fd is already installed ..."
  else
    print_info "Installing fd package ..."

    # shellcheck source=/dev/null
    source "$HOME/.cargo/env" || handle_error "Failed to source Cargo environment"

    # Install fd-find quietly using Cargo
    cargo install fd-find >/dev/null 2>&1 || handle_error "Failed to install fd package"

    # Verify fd installation
    if fd --version >/dev/null 2>&1; then
      print_success "fd installed successfully."
    else
      handle_error "Failed to verify fd installation."
    fi
  fi
}

install_fd
