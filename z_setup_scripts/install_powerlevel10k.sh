#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_powerlevel10k() {
  if [[ -d $ME/.powerlevel10k ]]; then
    print_info "PowerLevel10K is already installed ..."
  else
    print_info "Installing PowerLevel10K ..."

    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ME}/.powerlevel10k" ||
      handle_error "Failed to install PowerLevel10K to home directory"

    mkdir -p "${ME}/.oh-my-zsh"
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ME}/.oh-my-zsh/custom/themes/powerlevel10k" ||
      handle_error "Failed to install PowerLevel10K to zsh custom themes directory"

    print_success "PowerLevel10K installed successfully."
  fi
}

install_powerlevel10k
