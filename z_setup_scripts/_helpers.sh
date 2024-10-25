#!/bin/bash

if ! declare -p COLORS &>/dev/null; then
  declare -rA COLORS=(
    [RED]=$'\033[0;31m'
    [GREEN]=$'\033[0;32m'
    [BLUE]=$'\033[0;34m'
    [PURPLE]=$'\033[0;35m'
    [CYAN]=$'\033[0;36m'
    [WHITE]=$'\033[0;37m'
    [YELLOW]=$'\033[0;33m'
    [BOLD]=$'\033[1m'
    [OFF]=$'\033[0m'
  )
fi

print_message() {
  local color="$1"
  local message="$2"
  echo -e "${COLORS[${color}]}${message}${COLORS[OFF]}"
}

print_error() {
  print_message "RED" "ERROR: $1"
}

print_warning() {
  print_message "YELLOW" "WARNING: $1"
}

print_info() {
  print_message "CYAN" "INFO: $1"
}

print_success() {
  print_message "GREEN" "SUCCESS: $1"
}

handle_error() {
  print_error "$1"
  exit 1
}

install_with_package_manager() {
  local package="$1"
  print_info "Installing $package ..."
  if ! sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$package"; then
    handle_error "Failed to install $package"
  fi
}

link_file() {
  local source="$1"
  local destination="$2"
  print_info "Linking $source to $destination ..."
  sudo rm -rf "$destination" >/dev/null 2>&1
  if ! ln -s "$source" "$destination"; then
    handle_error "Failed to link $source to $destination"
  fi
}
