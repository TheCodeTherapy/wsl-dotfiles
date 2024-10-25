#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_rust() {
  if cargo --version >/dev/null 2>&1; then
    print_info "Rust is already installed ..."
  else
    print_info "Installing Rust ..."

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y >/dev/null 2>&1 ||
      handle_error "Failed to install Rust"

    # shellcheck source=/dev/null
    source "$HOME"/.cargo/env || handle_error "Failed to source Cargo environment"

    rustc --version >/dev/null 2>&1 || handle_error "Failed to verify Rust installation"

    print_success "Rust installed successfully."
  fi
}

install_rust
