#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_gcloud() {
  if gcloud --version >/dev/null 2>&1; then
    print_info "GCloud is already installed ..."
  else
    print_info "Installing GCloud ..."

    sudo apt-get install -y -qq apt-transport-https ca-certificates gnupg ||
      handle_error "Failed to install dependencies"

    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" |
      sudo tee -a /etc/apt/sources.list.d/google-cloud-sdk.list ||
      handle_error "Failed to add GCloud repository"

    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg |
      sudo apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - ||
      handle_error "Failed to add GCloud repository key"

    sudo apt-get update -qq || handle_error "Failed to update package list"

    sudo apt-get install -y -qq google-cloud-cli || handle_error "Failed to install GCloud"

    print_success "GCloud installed successfully."
  fi
}

install_gcloud
