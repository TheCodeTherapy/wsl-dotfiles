#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_helpers.sh"
source "$SCRIPT_DIR/_config.sh"

install_ytdlp() {
  if [[ -f $DOTDIR/bin/yt-dlp ]]; then
    print_info "YT-dlp is already installed ..."
  else
    print_info "Installing YT-dlp ..."

    mkdir -p $DOTDIR/bin

    cd "$DOTDIR" || handle_error "Failed to change directory to $DOTDIR"
    wget https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp_linux \
      -O "$DOTDIR"/bin/yt-dlp ||
      handle_error "Failed to download YT-dlp"

    print_success "YT-dlp installed successfully."
  fi
}

install_ytdlp
