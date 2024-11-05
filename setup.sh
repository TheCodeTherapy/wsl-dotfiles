#!/bin/bash

source "$(dirname "$0")/z_setup_scripts/_helpers.sh"
source "$(dirname "$0")/z_setup_scripts/_config.sh"

update_system() {
  print_info "Updating system ..."
  sudo apt-get update -qq || handle_error "Failed to update package lists."
  sudo apt-get full-upgrade -y -qq || handle_error "System update failed."
  sudo apt-get autoremove -y -qq || handle_error "Autoremove failed."
  sudo apt-get autoclean -y -qq || handle_error "Autoclean failed."
  sudo apt-get install -y -qq aptitude || handle_error "Failed to install aptitude."
}

install_basic_packages() {
  local packages=(
    build-essential llvm pkg-config autoconf automake cmake cmake-data
    autopoint ninja-build gettext libtool libtool-bin g++ make meson clang gcc
    nasm clang-tools dkms curl wget ca-certificates gnupg lsb-release gawk
    xclip notification-daemon git git-lfs zsh tmux inxi most tree tar jq pixz
    lzma unzip neofetch fonts-font-awesome timidity ttfautohint
    v4l2loopback-dkms ffmpeg htop bc fzf ranger ripgrep gdebi rar imagemagick
    net-tools xcb-proto dialog policykit-1 uthash-dev hashdeep file usbview
    v4l-utils python-is-python3 ipython3 python3-pip python3-dev python3-venv
    python3-gi python3-gi-cairo python3-cairo python3-setuptools python3-babel
    python3-dbus python3-pynvim python3-sphinx python3-packaging
    python3-xcbgen pipx xutils-dev valac hwdata bear p7zip-full
    zsh-autosuggestions zsh-syntax-highlighting
  )

  print_info "Installing basic packages ..."
  if ! sudo debconf-apt-progress -- apt-get install -y "${packages[@]}"; then
    handle_error "Failed to install one or more packages."
  fi
}

install_recipes() {
  local recipe_dir
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  recipe_dir="${SCRIPT_DIR}/z_setup_scripts"

  local recipes=(
    "$recipe_dir/install_rust.sh"
    "$recipe_dir/install_exa.sh"
    "$recipe_dir/install_fd.sh"
    "$recipe_dir/install_gcloud.sh"
    "$recipe_dir/install_githubcli.sh"
    "$recipe_dir/install_lazygit.sh"
    "$recipe_dir/install_tmuxpm.sh"
    "$recipe_dir/install_nvm.sh"
    "$recipe_dir/install_node.sh"
    "$recipe_dir/install_yarn.sh"
    "$recipe_dir/install_neovim.sh"
    "$recipe_dir/install_ytdlp.sh"
    "$recipe_dir/install_nginx.sh"
    "$recipe_dir/install_cloudflared.sh"
    "$recipe_dir/install_golang.sh"
    "$recipe_dir/install_oh-my-zsh.sh"
    "$recipe_dir/install_powerlevel10k.sh"
  )

  for recipe in "${recipes[@]}"; do
    if [ -f "$recipe" ]; then
      print_info "Running recipe: $(basename "$recipe")"
      # shellcheck source=/dev/null
      source "$recipe" || handle_error "Failed to execute recipe: $(basename "$recipe")"
    else
      print_warning "Recipe not found: $(basename "$recipe")"
    fi
  done
}

link_dotfiles() {
  local target_home="$HOME"
  local target_config="$HOME/.config"
  mkdir -p "$target_config/Code/User"
  declare -A files_to_link=(
    ["${DOTDOT}/bash/bashrc"]="$target_home/.bashrc"
    ["${DOTDOT}/bash/inputrc"]="$target_home/.inputrc"
    ["${DOTDOT}/profile/profile"]="$target_home/.profile"
    ["${DOTDOT}/neofetch"]="$target_config/neofetch"
    ["${DOTDOT}/nvim"]="$target_config/nvim"
    ["${DOTDOT}/vscode/settings.json"]="$target_config/Code/User/settings.json"
    ["${DOTDOT}/zsh/zshrc"]="$target_home/.zshrc"
    ["${DOTDOT}/zsh/zshenv"]="$target_home/.zshenv"
    ["${DOTDOT}/tmux/tmux.conf"]="$target_home/.tmux.conf"
  )

  for source_file in "${!files_to_link[@]}"; do
    local target_file="${files_to_link[$source_file]}"
    link_file "$source_file" "$target_file"
  done
}

update_system
install_basic_packages
install_recipes
link_dotfiles
