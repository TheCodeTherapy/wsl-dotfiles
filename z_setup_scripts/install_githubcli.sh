#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_githubcli() {
  if gh --version >/dev/null 2>&1; then
    print_info "Github CLI is already installed ..."
  else
    print_info "Installing Github CLI ..."

    sudo apt-get update -qq || handle_error "Failed to update package list"
    sudo apt-get install -y -qq wget || handle_error "Failed to install wget"

    sudo mkdir -p -m 755 /etc/apt/keyrings || handle_error "Failed to create keyrings directory"

    wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg |
      sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null ||
      handle_error "Failed to download keyring"

    sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg ||
      handle_error "Failed to change keyring permissions"

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" |
      sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null ||
      handle_error "Failed to add Github CLI repository"

    sudo apt-get update -qq || handle_error "Failed to update package list"

    sudo apt-get install -y -qq gh || handle_error "Failed to install Github CLI package"

    print_success "Github CLI installed successfully."
  fi
}

install_githubcli
