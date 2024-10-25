#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_neovim() {
  if [[ -f /usr/bin/nvim ]]; then
    print_info "Neovim is already installed ..."
  else
    print_info "Installing Neovim ..."

    cd "$DOTDIR" ||
      handle_error "Failed to change directory to $DOTDIR"

    rm -rf neovim ||
      handle_error "Failed to remove Neovim directory"

    git clone --quiet https://github.com/neovim/neovim ||
      handle_error "Failed to clone repository"

    cd neovim || handle_error "Failed to enter Neovim directory"

    git fetch --tags --quiet ||
      handle_error "Failed to fetch tags"

    git checkout v0.10.1 -q ||
      handle_error "Failed to checkout version v0.10.1"

    make CMAKE_BUILD_TYPE=RelWithDebInfo -j"$(nproc)" ||
      handle_error "Failed to build Neovim"

    cd build || handle_error "Failed to enter build directory"

    cpack -G DEB ||
      handle_error "Failed to create Neovim package"

    sudo dpkg -i --force-all nvim-linux64.deb ||
      sudo DEBIAN_FRONTEND=noninteractive apt-get install -f -y -qq ||
      handle_error "Failed to install Neovim package"

    cd "$DOTDIR" || handle_error "Failed to return to $DOTDIR"

    print_success "Neovim installed successfully."
  fi
}

install_neovim
