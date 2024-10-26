#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_golang() {
  if go version >/dev/null 2>&1; then
    print_info "Golang is already installed ..."
  else
    print_info "Installing Golang ..."

    export GOPATH="$ME/.go"

    # Create a temporary directory for the installation
    cd "$DOTDIR" || handle_error "Failed to change directory to $DOTDIR"
    mkdir -p temp || handle_error "Failed to create temporary directory"
    cd temp || handle_error "Failed to change directory to temporary folder"

    wget -q https://go.dev/dl/go1.23.0.linux-amd64.tar.gz || handle_error "Failed to download Golang package"

    sudo rm -rf /usr/local/go || handle_error "Failed to remove existing Golang installation"
    sudo tar -C /usr/local -xzf go1.23.0.linux-amd64.tar.gz || handle_error "Failed to install Golang"

    if ! grep -q '/usr/local/go/bin' "$HOME/.profile"; then
      # shellcheck disable=SC2016
      echo 'export PATH=$PATH:/usr/local/go/bin' >>"$HOME/.profile"
      print_info "Golang path added to $HOME/.profile"
    fi

    # shellcheck source=/dev/null
    source "$HOME/.profile" || handle_error "Failed to source .profile"

    # Verify Golang installation
    go version >/dev/null 2>&1 || handle_error "Failed to verify Golang installation"

    # Clean up by removing the temporary directory
    cd "$DOTDIR" || handle_error "Failed to return to $DOTDIR"
    rm -rf temp || handle_error "Failed to remove temporary directory"

    print_success "Golang installed successfully."
  fi
}

install_golang
