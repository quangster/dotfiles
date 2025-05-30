#!/bin/bash

# clear the screen
clear

# set some colors for output messages
OK="$(tput setaf 2)[OK]$(tput sgr0)"
ERROR="$(tput setaf 1)[ERROR]$(tput sgr0)"
NOTE="$(tput setaf 3)[NOTE]$(tput sgr0)"
INFO="$(tput setaf 4)[INFO]$(tput sgr0)"
WARN="$(tput setaf 1)[WARN]$(tput sgr0)"
CAT="$(tput setaf 6)[ACTION]$(tput sgr0)"
MAGENTA="$(tput setaf 5)"
ORANGE="$(tput setaf 214)"
WARNING="$(tput setaf 1)"
YELLOW="$(tput setaf 3)"
GREEN="$(tput setaf 2)"
BLUE="$(tput setaf 4)"
SKY_BLUE="$(tput setaf 6)"
RESET="$(tput sgr0)"


detect_os_info() {
    # Get kernel information
    KERNEL_NAME=$(uname -s)
    KERNEL_VERSION=$(uname -r)
    MACHINE_TYPE=$(uname -m)

    # Initialize OS variables
    OS_NAME="Unknown"
    OS_VERSION="Unknown"
    OS_CODENAME="Unknown"

    # Check for /etc/os-release (most modern Linux distros)
    if [ -f "/etc/os-release" ]; then
        source /etc/os-release
        OS_NAME=$NAME
        OS_VERSION=$VERSION_ID
        OS_CODENAME=$VERSION_CODENAME
    fi
}

install_package() {
    if sudo dpkg -l | grep -q -w "$1"; then
        printf "${OK} ${MAGENTA}$1${RESET} is already installed. Skipping\n"
    else
        stdbuf -oL sudo apt install -y "$1"
        # double check if the package was re-installed successfully
        if sudo dpkg -l | grep -q -w "$1"; then
            printf "${OK} ${SKY_BLUE}$1${RESET} has been installed successfully\n"
        else
            printf "${ERROR} ${YELLOW}$1${RESET} failed to install.\n"
        fi
    fi
}

apt_update() {
    printf "${NOTE} Updating ${SKY_BLUE}apt${RESET} ...\n"
    sudo apt update -y
    printf "${OK} ${SKY_BLUE}apt${RESET} has been updated successfully\n"
}

apt_upgrade() {
    printf "${NOTE} Upgrading ${SKY_BLUE}apt${RESET} ...\n"
    sudo apt upgrade -y
    printf "${OK} ${SKY_BLUE}apt${RESET} has been upgraded successfully\n"
}

detect_os_info

printf "${BLUE}"===================================================="${RESET}\n"
printf "${GREEN}Dotfiles installer for Ubuntu by @quangster${RESET}\n"
printf "${MAGENTA}User${RESET}: $(whoami)\n"
printf "${MAGENTA}Date${RESET}: $(date +"%Y-%m-%d %H:%M:%S")\n"
printf "${MAGENTA}Host${RESET}: $(hostname)\n"
printf "${MAGENTA}OS${RESET}: $OS_NAME $OS_VERSION ($OS_CODENAME)\n"
printf "${MAGENTA}Kernel${RESET}: $KERNEL_NAME $KERNEL_VERSION\n"
printf "${MAGENTA}Architecture${RESET}: $MACHINE_TYPE\n"
printf "${BLUE}"===================================================="${RESET}\n"


# ----------install some basic packages----------
apt_update
printf "\n%.0s" {1..1}

apt_upgrade
printf "\n%.0s" {1..1}

printf "${NOTE} Installing ${SKY_BLUE}some basic packages${RESET} ...${RESET}\n"
install_package "git"
install_package "curl"
install_package "wget"
install_package "htop"
install_package "ca-certificates"
install_package "gnome-terminal"
install_package "gpg"
install_package "apt-transport-https"
install_package "mpv"
printf "\n%.0s" {1..1}


# ----------install zsh----------
printf "${NOTE} Installing ${SKY_BLUE}core zsh${RESET} ...${RESET}\n"
install_package "zsh"
install_package "mercurial"
install_package "zplug"
printf "\n%.0s" {1..1}


# ----------install oh-my-zsh, plugins----------
if command -v zsh >/dev/null 2>&1; then
    printf "${NOTE} Installing ${SKY_BLUE}Oh My Zsh and plugins${RESET} ...\n"

    if [ ! -d "$HOME/.oh-my-zsh" ]; then  
        sh -c "$(curl -fsSL https://install.ohmyz.sh)" "" --unattended  	       
    else
        printf "${OK} Directory .oh-my-zsh already exists. Skipping re-installation.\n"
    fi

    # check if the directories exist before cloning the repositories
    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]; then
        git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions 
    else
        printf "${OK} Directory zsh-autosuggestions already exists. Skipping re-installation.\n"
    fi

    if [ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]; then
        git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
    else
        printf "${OK} Directory zsh-syntax-highlighting already exists. Skipping re-installation.\n"
    fi

    # check if ~/.zshrc and .zprofile exists, create a backup, and copy the new configuration
    if [ -f "$HOME/.zshrc" ]; then
        cp -b "$HOME/.zshrc" "$HOME/.zshrc-backup" || true
    fi

    if [ -f "$HOME/.zprofile" ]; then
        cp -b "$HOME/.zprofile" "$HOME/.zprofile-backup" || true
    fi

    # copy the preconfigured zsh themes and profile
    cp -r 'zsh/.zshrc' ~/
    cp -r 'zsh/.zprofile' ~/

    # set zsh as the default shell
    if [[ "$SHELL" != *"zsh"* ]]; then
        printf "${NOTE} Setting ${SKY_BLUE}zsh as the default shell${RESET} ...\n"

        while ! chsh -s $(which zsh); do
            printf "${ERROR} Authentication failed. Please enter the correct password.\n"
            sleep 1
        done

        printf "${OK} Shell changed successfully to ${MAGENTA}zsh${RESET}\n"
    else
        printf "${OK} Your shell is already set to ${MAGENTA}zsh${RESET}.\n"
    fi

    # copy additional oh-my-zsh themes from assets
    if [ -d "$HOME/.oh-my-zsh/themes" ]; then
        cp -r ./zsh/themes/* ~/.oh-my-zsh/themes
    fi
fi

printf "\n%.0s" {1..1}


# ----------install docker----------
printf "${NOTE} Installing ${SKY_BLUE}docker, docker compose${RESET} ...${RESET}\n"
apt_update
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    printf "${OK} ${SKY_BLUE}docker${RESET} has been installed successfully\n"
else
    printf "${OK} ${MAGENTA}docker${RESET} is already installed. Skipping\n"
fi
apt_update
install_package "docker-compose-plugin"
printf "\n%.0s" {1..1}


# ----------install miniconda----------
printf "${NOTE} Installing ${SKY_BLUE}miniconda${RESET} ...${RESET}\n"
if ! command -v conda >/dev/null 2>&1; then
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o miniconda.sh
    chmod +x miniconda.sh
    bash miniconda.sh -b -p $HOME/miniconda
    $HOME/miniconda/bin/conda init bash
    $HOME/miniconda/bin/conda init zsh
    rm miniconda.sh
    printf "${OK} ${SKY_BLUE}miniconda${RESET} has been installed successfully\n"
else
    $HOME/miniconda/bin/conda init bash
    $HOME/miniconda/bin/conda init zsh
    printf "${OK} ${MAGENTA}miniconda${RESET} is already installed. Skipping\n"
fi
printf "\n%.0s" {1..1}


# ----------install vscode----------
printf "${NOTE} Installing ${SKY_BLUE}Visual Studio Code${RESET} ...${RESET}\n"
if ! command -v code >/dev/null 2>&1; then
    wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > packages.microsoft.gpg
    sudo install -D -o root -g root -m 644 packages.microsoft.gpg /etc/apt/keyrings/packages.microsoft.gpg
    echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
    rm -f packages.microsoft.gpg
    apt_update
    install_package "code"
else
    printf "${OK} ${MAGENTA}Visual Studio Code${RESET} is already installed. Skipping\n"
fi
printf "\n%.0s" {1..1}


# ----------install ms edge----------
printf "${NOTE} Installing ${SKY_BLUE}Microsoft Edge${RESET} ...${RESET}\n"
if ! command -v microsoft-edge-stable >/dev/null 2>&1; then
    echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/edge stable main" | sudo tee /etc/apt/sources.list.d/microsoft-edge.list > /dev/null
    apt_update
    install_package "microsoft-edge-stable"
else
    printf "${OK} ${MAGENTA}Microsoft Edge${RESET} is already installed. Skipping\n"
fi
printf "\n%.0s" {1..1}


# ----------install spotify----------
printf "${NOTE} Installing ${SKY_BLUE}Spotify${RESET} ...${RESET}\n"
if ! command -v spotify >/dev/null 2>&1; then
    curl -sS https://download.spotify.com/debian/pubkey_C85668DF69375001.gpg | sudo gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/spotify.gpg
    echo "deb http://repository.spotify.com stable non-free" | sudo tee /etc/apt/sources.list.d/spotify.list
    apt_update
    install_package "spotify-client"
else
    printf "${OK} ${MAGENTA}Spotify${RESET} is already installed. Skipping\n"
fi
printf "\n%.0s" {1..1}


# ----------install ibus-bamboo----------
printf "${NOTE} Installing ${SKY_BLUE}ibus-bamboo${RESET} ...${RESET}\n"
if ! command -v ibus >/dev/null 2>&1; then
    printf "${NOTE} Installing ${SKY_BLUE}ibus-bamboo${RESET} ...${RESET}\n"
    sudo add-apt-repository -y ppa:bamboo-engine/ibus-bamboo
    apt_update
    install_package "ibus"
    install_package "ibus-bamboo"
    ibus restart
    env DCONF_PROFILE=ibus dconf write /desktop/ibus/general/preload-engines "['BambooUs', 'Bamboo']" && gsettings set org.gnome.desktop.input-sources sources "[('xkb', 'us'), ('ibus', 'Bamboo')]"
else
    printf "${OK} ${MAGENTA}ibus-bamboo${RESET} is already installed. Skipping\n"
fi
printf "\n%.0s" {1..1}


# ----------install kitty terminal----------
printf "${NOTE} Installing ${SKY_BLUE}kitty${RESET} ...${RESET}\n"
install_package "kitty"
# copy the kitty configuration file
printf "${NOTE} Copying ${SKY_BLUE}kitty configuration${RESET} ...${RESET}\n"
mkdir -p ~/.config/kitty
printf "\n%.0s" {1..1}


# ----------install yazi----------
printf "${NOTE} Installing ${SKY_BLUE}yazi${RESET} ...${RESET}\n"
if command -v yazi >/dev/null 2>&1; then
    printf "${OK} ${MAGENTA}yazi${RESET} is already installed. Skipping\n"
else
    yazi=(
        ffmpeg 
        7zip 
        jq 
        poppler-utils 
        fd-find 
        ripgrep 
        fzf 
        zoxide 
        imagemagick
    )
    for i in "${yazi[@]}"; do
        install_package "$i"
    done
    stdbuf -oL sudo snap install yazi --classic
    # double check if the package was re-installed successfully
    if command -v yazi >/dev/null 2>&1; then
        printf "${OK} ${SKY_BLUE}yazi${RESET} has been installed successfully\n"
    else
        printf "${ERROR} ${YELLOW}yazi${RESET} failed to install.\n"
    fi
fi
# copy the yazi configuration file
printf "${NOTE} Copying ${SKY_BLUE}yazi configuration${RESET} ...${RESET}\n"
if [ ! -d "$HOME/.config/yazi" ]; then
    mkdir -p "$HOME/.config/yazi"
fi
cp -r yazi/* ~/.config/yazi
printf "\n%.0s" {1..1}


# ----------install anki----------
printf "${NOTE} Installing ${SKY_BLUE}Anki${RESET} ...${RESET}\n"
if command -v anki > /dev/null 2>&1; then
    printf "${OK} ${MAGENTA}Anki${RESET} is already installed. Skipping\n"
else
    install_package "libxcb-xinerama0"
    install_package "libxcb-cursor0"
    install_package "libnss3"
    ANKI_URL="https://github.com/ankitects/anki/releases/download/25.02/anki-25.02-linux-qt6.tar.zst"
    ANKI_FILE="anki.tar.zst"
    wget -q --show-progress $ANKI_URL -O $ANKI_FILE
    tar xaf $ANKI_FILE
    cd anki
    sudo ./install.sh
    rm -rf ../anki $ANKI_FILE
    if command -v anki > /dev/null 2>&1; then
        printf "${OK} ${SKY_BLUE}Anki${RESET} has been installed successfully\n"
    else
        printf "${ERROR} ${YELLOW}Anki${RESET} failed to install.\n"
    fi
fi
printf "\n%.0s" {1..1}


# install tailscale
printf "${NOTE} Installing ${SKY_BLUE}Tailscale${RESET} ...${RESET}\n"
if command -v tailscale > /dev/null 2>&1; then
    printf "${OK} ${MAGENTA}Tailscale${RESET} is already installed. Skipping\n"
else
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.noarmor.gpg | sudo tee /usr/share/keyrings/tailscale-archive-keyring.gpg >/dev/null
    curl -fsSL https://pkgs.tailscale.com/stable/ubuntu/noble.tailscale-keyring.list | sudo tee /etc/apt/sources.list.d/tailscale.list
    apt_update
    install_package "tailscale"
    if command -v tailscale > /dev/null 2>&1; then
        printf "${OK} ${SKY_BLUE}Tailscale${RESET} has been installed successfully\n"
    else
        printf "${ERROR} ${YELLOW}Tailscale${RESET} failed to install.\n"
    fi
fi
printf "\n%.0s" {1..1}


# ----------install yt-dlp----------
printf "${NOTE} Installing ${SKY_BLUE}yt-dlp${RESET} ...${RESET}\n"
if command -v yt-dlp > /dev/null 2>&1; then
    printf "${OK} ${MAGENTA}yt-dlp${RESET} is already installed. Skipping\n"
else
    sudo add-apt-repository ppa:tomtomtom/yt-dlp 
    apt_update
    install_package "yt-dlp"
    if command -v yt-dlp > /dev/null 2>&1; then
        printf "${OK} ${SKY_BLUE}yt-dlp${RESET} has been installed successfully\n"
    else
        printf "${ERROR} ${YELLOW}yt-dlp${RESET} failed to install.\n"
    fi
fi
printf "\n%.0s" {1..1}