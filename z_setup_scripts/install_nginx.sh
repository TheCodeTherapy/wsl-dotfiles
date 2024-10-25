#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_nginx() {
  if nginx -version >/dev/null 2>&1; then
    print_info "Nginx is already installed ..."
  else
    print_info "Installing Nginx ..."

    sudo apt-get install -y -qq nginx ||
      handle_error "Failed to install Nginx"

    if [[ -f /etc/nginx/ssl/localhost.crt ]]; then
      print_info "nginx self-signed certificated already created."
    else
      print_info "Creating self-signed certificate for nginx ..."

      sudo mkdir -p /etc/nginx/ssl || handle_error "Failed to create /etc/nginx/ssl directory"

      cd /etc/nginx/ssl || handle_error "Failed to change directory to /etc/nginx/ssl"
      sudo openssl req -x509 -nodes -days 1825 -newkey rsa:2048 \
        -keyout localhost.key -out localhost.crt ||
        handle_error "Failed to create self-signed certificate"

      print_success "Self-signed certificate created successfully."
    fi

    sudo cp /etc/nginx/sites-available/default /etc/nginx/sites-available/default.bak ||
      handle_error "Failed to backup default nginx configuration"

    sudo cp $DOTDOT/nginx/defult.conf /etc/nginx/sites-available/default ||
      handle_error "Failed to copy default nginx configuration"

    sudo nginx -t || handle_error "Failed to test nginx configuration"
    sudo systemctl reload nginx || handle_error "Failed to reload nginx"

    print_success "Nginx installed successfully."
  fi
}

install_nginx
