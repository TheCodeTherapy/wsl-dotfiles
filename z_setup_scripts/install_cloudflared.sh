#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_cloudflared() {
  if cloudflared --version >/dev/null 2>&1; then
    print_info "Cloudflared is already installed ..."
  else
    print_info "Installing Cloudflared ..."

    sudo mkdir -p --mode=0755 /usr/share/keyrings || handle_error "Failed to create keyrings directory"

    curl -fsSL https://pkg.cloudflare.com/cloudflare-main.gpg |
      sudo tee /usr/share/keyrings/cloudflare-main.gpg >/dev/null ||
      handle_error "Failed to download Cloudflared repository key"

    echo 'deb [signed-by=/usr/share/keyrings/cloudflare-main.gpg] https://pkg.cloudflare.com/cloudflared jammy main' |
      sudo tee /etc/apt/sources.list.d/cloudflared.list ||
      handle_error "Failed to add Cloudflared repository"

    sudo apt-get update -qq || handle_error "Failed to update package list"

    sudo apt-get install -y -qq cloudflared || handle_error "Failed to install Cloudflared"

    print_success "Cloudflared installed successfully."
  fi
}

install_cloudflared
