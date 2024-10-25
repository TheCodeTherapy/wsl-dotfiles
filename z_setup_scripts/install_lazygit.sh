#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_lazygit() {
  if lazygit --version >/dev/null 2>&1; then
    print_info "Lazygit is already installed ..."
  else
    print_info "Installing Lazygit ..."

    cd "$DOTDIR" || handle_error "Failed to change directory to $DOTDIR"
    mkdir -p temp || handle_error "Failed to create temporary directory"
    cd temp || handle_error "Failed to change directory to temporary folder"

    LAZYGIT_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazygit/releases/latest" | grep -Po '"tag_name": "v\K[^"]*') ||
      handle_error "Failed to fetch Lazygit version"

    curl -Lo lazygit.tar.gz "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz" >/dev/null 2>&1 ||
      handle_error "Failed to download Lazygit package"

    tar xf lazygit.tar.gz lazygit || handle_error "Failed to extract Lazygit package"

    sudo install lazygit /usr/local/bin || handle_error "Failed to install Lazygit"

    cd "$DOTDIR" || handle_error "Failed to return to $DOTDIR"
    rm -rf temp || handle_error "Failed to remove temporary directory"

    print_success "Lazygit installed successfully."
  fi
}

install_lazygit
