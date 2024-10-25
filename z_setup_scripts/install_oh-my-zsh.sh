#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_ohmyzsh() {
  if [[ -d $ME/.oh-my-zsh ]]; then
    print_info "OhMyZSH is already installed ..."
  else
    print_info "Installing OhMyZSH ..."

    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

    print_success "OhMyZSH installed successfully."
  fi
}

install_ohmyzsh
