#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

LOGFILE="wine-installation.log"

printf "${GREEN}Starting Wine installation...${NC}\n"
printf "Starting Wine installation...\n" > "$LOGFILE"

enable_32bit_architecture() {
    printf "${GREEN}Enabling 32-bit architecture...${NC}\n"
    printf "Enabling 32-bit architecture...\n" >> "$LOGFILE"
    sudo dpkg --add-architecture i386 2>&1 | tee -a "$LOGFILE"
}

add_repository_key() {
    printf "${GREEN}Adding WineHQ repository key...${NC}\n"
    printf "Adding WineHQ repository key...\n" >> "$LOGFILE"
    wget -nc https://dl.winehq.org/wine-builds/winehq.key 2>&1 | tee -a "$LOGFILE" &&
    sudo apt-key add winehq.key 2>&1 | tee -a "$LOGFILE" &&
    rm winehq.key
}

add_winehq_repository() {
    printf "${GREEN}Adding the WineHQ repository...${NC}\n"
    printf "Adding the WineHQ repository...\n" >> "$LOGFILE"
    sudo add-apt-repository 'deb https://dl.winehq.org/wine-builds/ubuntu/ focal main' 2>&1 | tee -a "$LOGFILE"
}

update_package_lists() {
    printf "${GREEN}Updating package lists...${NC}\n"
    printf "Updating package lists...\n" >> "$LOGFILE"
    sudo apt update 2>&1 | tee -a "$LOGFILE"
}

install_wine() {
    local version="$1"
    printf "${GREEN}Installing Wine $version...${NC}\n"
    printf "Installing Wine $version...\n" >> "$LOGFILE"
    sudo apt install --install-recommends "$version" 2>&1 | tee -a "$LOGFILE"
}

fix_broken_packages() {
    printf "${YELLOW}Attempting to fix broken packages...${NC}\n"
    printf "Attempting to fix broken packages...\n" >> "$LOGFILE"
    sudo apt --fix-broken install 2>&1 | tee -a "$LOGFILE"
}

show_gui_selection() {
    local choice
    choice=$(whiptail --title "Wine Installation" --menu "Choose Wine version to install:" 15 60 3 \
        "1" "Wine Stable 9.0" \
        "2" "Wine Development" \
        "3" "Wine Staging" 3>&1 1>&2 2>&3)

    case $choice in
        1) WINE_VERSION="winehq-stable";;
        2) WINE_VERSION="winehq-devel";;
        3) WINE_VERSION="winehq-staging";;
        *) printf "${RED}Invalid selection. Exiting.${NC}\n" >&2; exit 1;;
    esac
}

ask_remove_old_versions() {
    if whiptail --title "Wine Installation" --yesno "Do you want to remove old Wine versions?" 10 60; then
        printf "${YELLOW}Removing old Wine versions...${NC}\n"
        sudo apt remove --purge wine\* -y 2>&1 | tee -a "$LOGFILE"
    fi
}

main() {
    enable_32bit_architecture
    add_repository_key
    add_winehq_repository
    update_package_lists
    show_gui_selection
    ask_remove_old_versions
    if ! install_wine $WINE_VERSION; then
        fix_broken_packages
        if ! install_wine $WINE_VERSION; then
            printf "${RED}Wine installation failed after attempting to fix broken packages. Check the log file for details.${NC}\n" >&2
            printf "Wine installation failed after attempting to fix broken packages.\n" >> "$LOGFILE"
            return 1
        else
            printf "${GREEN}Wine installation completed successfully after fixing broken packages.${NC}\n"
            printf "Wine installation completed successfully after fixing broken packages.\n" >> "$LOGFILE"
        fi
    else
        printf "${GREEN}Wine installation completed successfully.${NC}\n"
        printf "Wine installation completed successfully.\n" >> "$LOGFILE"
    fi
}

main "$@"

