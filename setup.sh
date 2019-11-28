#!/bin/bash

ME="/home/$(whoami)"
CFG="$ME/.config"

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

print_success () {
    echo -e "\n${COLORS[GREEN]}${1}${COLORS[OFF]}\n"
}

print_info () {
    echo -e "\n${COLORS[CYAN]}${1}${COLORS[OFF]}\n"
}

print_fail () {
    echo -e "\n${COLORS[RED]}${1}${COLORS[OFF]}\n"
}

home_link () {
    sudo rm -rf $ME/$2 > /dev/null 2>&1 \
        && ln -s $ME/wsl-dotfiles/$1 $ME/$2 \
        || ln -s $ME/wsl-dotfiles/$1 $ME/$2
    msg="# Linked $ME/wsl-dotfiles/$1 to -> $ME/$2"
    print_info "${msg}"
}

home_link_cfg () {
    mkdir -p $CFG
    sudo rm -rf $CFG/$1 > /dev/null 2>&1 \
        && ln -s $ME/wsl-dotfiles/$1 $CFG/. \
        || ln -s $ME/wsl-dotfiles/$1 $CFG/.
    msg="# Linked $ME/wsl-dotfiles/$1 to dir -> $CFG/$1"
    print_info "${msg}"
}

GCR="deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"

choose_fastest_mirror () {
    msg="# Checking mirrors speed (please wait)..."
    print_success "${msg}"
    fastest=$(curl -s http://mirrors.ubuntu.com/mirrors.txt \
        | xargs -n1 -I {} sh -c 'echo `curl -r 0-102400 -s -w %{speed_download} -o /dev/null {}/ls-lR.gz` {}' \
        | sort -g -r \
        | head -1 \
        | awk '{ print $2 }')
    echo $fastest
    cn=$(lsb_release -cs)
    mirror="deb $fastest"
    list="$mirror $cn main restricted"
    list="$list\n$mirror $cn-updates main restricted"
    list="$list\n$mirror $cn universe"
    list="$list\n$mirror $cn-updates universe"
    list="$list\n$mirror $cn multiverse"
    list="$list\n$mirror $cn-updates multiverse"
    list="$list\n$mirror $cn-backports main restricted universe multiverse"
    list="$list\n$mirror $cn-security main restricted"
    list="$list\n$mirror $cn-security universe"
    list="$list\n$mirror $cn-security multiverse"
    echo -e $list | sudo tee /etc/apt/sources.list
}

update_system () {
    msg="# Updating your system (please wait)..."
    print_success "${msg}"
    sudo apt -y update && sudo apt -y upgrade
}

install_basic_packages () {
    msg="# Installing basic software (please wait)..."
    print_success "${msg}"
    sudo apt -y install unzip lzma tree neofetch build-essential autoconf \
        automake cmake cmake-data pkg-config clang git neovim zsh python3 \
        ipython3 python3-pip python-pip powerline fonts-powerline ruby-full
    rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
}

install_nvm () {
    msg="# Installing nvm (please wait)..."
    print_success "${msg}"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash
    source $ME/.bashrc
}

install_node () {
    if [ -z $NVM_DIR ]; then
        if [[ -f $ME/.nvm/nvm.sh ]]; then
            export NVM_DIR="$HOME/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
            [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"
        else
            install_nvm
        fi
        msg="# Installing NodeJS (please wait)..."
        print_success "${msg}"
        nvm install 12.13.1
    else
        if $(nvm --version > /dev/null 2>&1); then
            msg="# Installing NodeJS (please wait)..."
            print_success "${msg}"
            nvm install 12.13.1
        fi
    fi
}

install_neovim_deps () {
    if $(find ~ -type d -name neovim | grep neovim > /dev/null 2>&1); then
        msg="Node neovim provider already installed."
        print_success "${msg}"
    else
        msg="# Installing Node neovim provider (please wait)..."
        print_success "${msg}"
        npm install -g neovim
    fi
    if $(pip3 show pynvim > /dev/null 2>&1); then
        msg="PyNvim installed for Python 3."
        print_success "${msg}"
    else
        msg="Installing PyNvim installed for Python 3 (please wait)..."
        print_success "${msg}"
        sudo -H pip3 install pynvim
    fi
    if $(pip2 show neovim &> /dev/null); then
        msg="PyNvim installed for Python 2."
        print_success "${msg}"
    else
        msg="Installing PyNvim installed for Python 2 (please wait)..."
        print_success "${msg}"
        sudo -H pip2 install neovim
    fi
    if [[ -f /usr/local/bin/neovim-ruby-host ]]; then
        msg="neovim-ruby-host already installed."
        print_success "${msg}"
    else
        msg="Installing neovim-ruby-host (please wait)..."
        print_success "${msg}"
        sudo gem install neovim
    fi
}

cd $ME

choose_fastest_mirror
update_system
install_basic_packages

home_link "bash/bashrc" ".bashrc"
home_link "bash/inputrc" ".inputrc"
home_link "zsh/oh-my-zsh" ".oh-my-zsh"
home_link "zsh/zshrc" ".zshrc"

if [[ -f $ME/.nvm/nvm.sh ]]; then
    source $ME/.bashrc
else
    install_nvm
fi

if $(node --version > /dev/null 2>&1); then
    msg="NodeJS already installed."
    print_success "${msg}"
else
    install_node
fi

install_neovim_deps

home_link_cfg "nvim"

# if [[ -f /bin/zsh ]]; then
#     if [ $SHELL != "/bin/zsh" ]; then
#         chsh -s /bin/zsh
#     fi
# fi
