#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_tmux_plugin_manager() {
  if [[ -d $ME/.tmux/plugins/tpm ]]; then
    print_info "Tmux Plugin Manager is already installed ..."
  else
    print_info "Installing Tmux Plugin Manager ..."

    git clone --quiet https://github.com/tmux-plugins/tpm "${ME}/.tmux/plugins/tpm" >/dev/null 2>&1 ||
      handle_error "Failed to install Tmux Plugin Manager"

    print_success "Tmux Plugin Manager installed successfully."
  fi
}

install_tmux_plugin_manager
