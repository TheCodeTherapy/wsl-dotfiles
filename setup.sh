#!/bin/bash
set -eu -o pipefail

ME="/home/$(whoami)"
CFG="$ME/.config"
DOTDIR="${ME}/wsl-dotfiles"
NVMDIR="${ME}/.nvm"
BINDIR="${DOTDIR}/bin"

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

print_red () {
    echo -e "\n${COLORS[RED]}${1}${COLORS[OFF]}\n"
}

print_yellow () {
    echo -e "\n${COLORS[YELLOW]}${1}${COLORS[OFF]}\n"
}

print_green () {
    echo -e "\n${COLORS[GREEN]}${1}${COLORS[OFF]}\n"
}

print_cyan () {
    echo -e "\n${COLORS[CYAN]}${1}${COLORS[OFF]}\n"
}

wait_key () {
    echo -e "\n${COLORS[YELLOW]}"
    read -n 1 -s -r -p "${1}"
    echo -e "${COLORS[OFF]}\n"
}

home_link () {
    sudo rm -rf $ME/$2 > /dev/null 2>&1 \
        && ln -s $DOTDIR/$1 $ME/$2 \
        || ln -s $DOTDIR/$1 $ME/$2
    msg="# Linked $DOTDIR/$1 to -> $ME/$2"
    print_cyan "${msg}"
}

home_link_cfg () {
    mkdir -p $CFG
    sudo rm -rf $CFG/$1 > /dev/null 2>&1 \
        && ln -s $DOTDIR/$1 $CFG/. \
        || ln -s $DOTDIR/$1 $CFG/.
    msg="# Linked $DOTDIR/$1 to dir -> $CFG/$1"
    print_cyan "${msg}"
}

update_system () {
    msg="# Updating your system (please wait)..."
    print_green "${msg}"
    # echo "nameserver 8.8.8.8" | sudo tee /etc/resolv.conf > /dev/null
    sudo apt -y update && sudo apt -y upgrade
}

install_basic_packages () {
    msg="# Installing basic packages (please wait)..."
    print_green "${msg}"
    sudo apt -y install unzip lzma tree neofetch build-essential autoconf \
        automake cmake cmake-data pkg-config clang git neovim zsh python3 \
        ipython3 python3-pip python3-dev python-is-python3 tmux ffmpeg \
		    wget dialog ninja-build gettext curl
    rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
}

install_nvm () {
    msg="INSTALLING NVM ..."
    print_yellow "${msg}"
    if [[ -f $NVMDIR/nvm.sh ]]; then
        print_green "nvm already installed."
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
    fi
}

install_node () {
    msg="INSTALLING NODEJS ..."
    print_yellow "${msg}"
    if [[ -f $NVMDIR/nvm.sh ]]; then
        if $(npm --version > /dev/null 2>&1); then
            msg="npm already installed."
            print_green "${msg}"
        else
            source $NVMDIR/nvm.sh
            VER=$(nvm ls-remote --lts | grep "Latest" | tail -n 1 | sed 's/[-/a-zA-Z]//g' | sed 's/^[ \t]*//')
            msg="Installing Latest NodeJS version found: ${VER}"
            print_yellow "${msg}"
            nvm install $VER
        fi
    else
        msg="nvm not installed."
        print_red "${msg}"
    fi
}

install_pnpm () {
    msg="INSTALLING PNPM ..."
    print_yellow "${msg}"
    curl -fsSL https://get.pnpm.io/install.sh | sh -
}

install_yarn () {
    if $(yarn --version > /dev/null 2>&1); then
        msg="Yarn already installed."
        print_green "${msg}"
    else
        msg="Installing Yarn..."
        print_yellow "${msg}"
        corepack enable
        corepack prepare yarn@stable --activate
    fi
}

install_awscli () {
    if $(aws --version > /dev/null 2>&1); then
        msg="AWS CLI already installed."
        print_green "${msg}"
    else
        msg="Installing AWS CLI..."
        print_cyan "${msg}"
        pip3 install awscli --upgrade --user
    fi
}

install_nvim () {
    msg="# Installing latest neovim (please wait)..."
    print_green "${msg}"
    sudo add-apt-repository -y ppa:neovim-ppa/stable
    sudo apt -y update
    sudo apt -y install neovim
    sudo apt -y autoremove
}

install_latest_nvim() {
    msg="# Installing latest neovim (please wait)..."
    print_green "${msg}"
    c="$(lscpu -p | grep -v '#' | wc -l)"
    cd $ME
    git clone https://github.com/neovim/neovim.git
    cd neovim
    git checkout v0.9.4
    make -j$c CMAKE_BUILD_TYPE=Release
}

install_exa () {
    if [[ -f $BINDIR/exa ]]; then
        msg="Exa already installed."
        print_green "${msg}"
    else
        msg="# Downloading Exa (please wait)..."
        print_green "${msg}"
        cd $BINDIR \
            && mkdir exa-10.0.1 && cd exa-10.0.1 \
            && wget https://github.com/ogham/exa/releases/download/v0.10.1/exa-linux-x86_64-v0.10.1.zip \
            && unzip exa-linux-x86_64-v0.10.1.zip \
            && rm exa-linux-x86_64-v0.10.1.zip \
            && cd $BINDIR \
            && ln -s ./exa-10.0.1/bin/exa . \
            && cd ..
    fi
}

cd $ME

update_system
install_basic_packages
install_awscli
#install_nvim
# install_latest_nvim
install_exa

home_link "bash/bashrc.sh" ".bashrc"
home_link "bash/inputrc.sh" ".inputrc"
home_link "tmux/tmux.conf" ".tmux.conf"
home_link "tmux/tmux.conf.local" ".tmux.conf.local"
home_link "tmux/tmux.help" ".tmux.help"

# if [[ -f $ME/.nvm/nvm.sh ]]; then
#     source $ME/.bashrc
# else
#     install_nvm
# fi

# if $(node --version > /dev/null 2>&1); then
#     msg="NodeJS already installed."
#     print_green "${msg}"
# else
#     install_node
# fi

# if $(pnpm --version > /dev/null 2>&1); then
#     msg="PNPM already installed."
#     print_green "${msg}"
# else
#     install_pnpm
# fi

install_yarn

sudo usermod -s /usr/bin/zsh $(whoami)
