#!/bin/bash

ME="/home/$(whoami)"

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

home_link () {
    sudo rm -rf $ME/$2 > /dev/null 2>&1 \
        && ln -s $ME/wsl-dotfiles/$1 $ME/$2 \
        || ln -s $ME/wsl-dotfiles/$1 $ME/$2
}

GCR="deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main"

choose_fastest_mirror () {
    msg="# Checking mirrors speed (please wait)..."
    echo -e "\n${COLORS[GREEN]}${msg}${COLORS[OFF]}\n"
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
    echo -e "\n${COLORS[GREEN]}${msg}${COLORS[OFF]}\n"
    sudo apt -y update && sudo apt -y upgrade
}

install_basic_packages () {
    msg="# Installing basic software (please wait)..."
    echo -e "\n${COLORS[GREEN]}${msg}${COLORS[OFF]}\n"
    sudo apt -y install unzip lzma tree neofetch build-essential autoconf \
        automake cmake cmake-data pkg-config clang git neovim zsh python3 \
        ipython3 python3-pip powerline fonts-powerline
    rc=$?; if [[ $rc != 0 ]]; then exit $rc; fi
}

choose_fastest_mirror
update_system
install_basic_packages

cd $ME

home_link "bash/bashrc" ".bashrc"
home_link "zsh/oh-my-zsh" ".oh-my-zsh"
home_link "zsh/zshrc" ".zshrc"

if [[ -f $ME/.nvm/nvm.sh ]]; then
    source .bashrc
else
    mgs="# Installing nvm (please wait)..."
    echo -e "\n${COLORS[GREEN]}${msg}${COLORS[OFF]}\n"
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.35.1/install.sh | bash
    source .bashrc
fi

# if [[ -f /bin/zsh ]]; then
#     if [ $SHELL != "/bin/zsh" ]; then
#         chsh -s /bin/zsh
#     fi
# fi

