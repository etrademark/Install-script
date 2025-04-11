#!/bin/bash

### Variables
installDir="./output"
mkdir -p "$installDir/logs"

zsh="zsh"
hyprland="hyprland noto-fonts kitty"
dotfiles="rofi wofi wl-clipboard thunar blueman networkmanager ttf-jetbrains-mono-nerd ttf-font-awesome network-manager-applet pulseaudio pavucontrol alsa-firmware cava waybar"
lazyvim="neovim nodejs npm ripgrep stylua lua51 luarocks hererocks fd lazygit fzf ghostscript shfmt ast-grep nix"

asusctl="asusctl supergfxctl rog-control-center"

# ANSI Color codes
RESET='\e[0m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
LIGHT_YELLOW='\e[38;5;229m'
ORANGE='\e[38;5;214m'
CYAN='\033[0;36m' # Directories
WARNING=" - ${YELLOW}[${ORANGE}!${YELLOW}]${LIGHT_YELLOW} "
ERROR=" - ${RED}[${ORANGE}!${RED}] "
NOTE=" - ${LIGHT_YELLOW}[${RESET}!${LIGHT_YELLOW}]${RESET} "
IMPORTANT=" - ${RESET}{${CYAN}IMPORTANT${RESET}}${YELLOW} "
echo -e "${WARNING}This script is still in development. Please use it with caution.${RESET}\n"

if hash paru 2>/dev/null; then
  helper='paru'
elif hash yay 2>/dev/null; then
  helper='yay'
else
  noHelper=true
fi

cancel() {
  if [[ $? = 1 || $? = 255 ]]; then
    echo -e "${RED}User canceled, stopping...${RESET}\n"
    exit 1
  fi
}

#whiptail --title "Hyprland-Dots"  'This will remove the backups ending with ".bak" of the applications you will configure later. It will not remove anything unrelated to the things you selected.' 15 75
#cancel

installOptions=$(whiptail --title "Hyprland-Dots install script" --checklist "Choose options to install or configure" 15 100 5 \
  "zim-powerlevel10k" "Configure and change shell to zsh (+ zim) with powerlevel10k theming" off \
  "lazyvim" "Install LazyVim and neovim text editor (command: nvim)" off \
  "hyprland" "Plain Hyprland without dotfiles (unless previously configured)" off \
  "dotfiles" "Configure Hyprland with etrademark's dotfiles" off \
  "developer" "Install some additional programming languages and developer tools" off \
  2>&1 >/dev/tty)
cancel

if [[ $installOptions == *"languages"* ]]; then
  echo e
  #dev=$(whiptail)
fi

function rog_check() {
  if [[ $(hostnamectl) == *"ASUSTeK COMPUTER INC."* ]]; then
    if [[ $(hostnamectl) == *[Ll]"aptop"* ]]; then
      if whiptail --title "ROG" --yesno "You seem to have an ASUS device.\nDo you want to install asus-linux and supergfxctl (recommended for ROG and TUF laptops)?" 10 50; then
        asusctl=""
      else
        echo -e "${NOTE}Installing asus-linux and supergfxctl (recommended for ROG and TUF laptops).\n"
      fi
    fi
  fi
}
echo -e "${NOTE}Installing required packages and setting up permissions.\n"
sudo pacman -Sy --noconfirm --needed base-devel cargo git wget curl unzip

if [ "$noHelper" = true ]; then
  aurHelper=$(whiptail --title "AUR Helper not installed." --radiolist \
    "Choose an AUR Helper:" 15 50 2 \
    "paru" "Install Paru" on \
    "yay" "Install Yay" off \
    2>&1 >/dev/tty)
  cancel

  helper=$aurHelper

  echo -e "${NOTE}Installing the AUR Helper ${helper}.\n"
  git clone "https://aur.archlinux.org/${helper}-bin.git" "${installDir}/${helper}"
  mkdir -p "${installDir}/${helper}"
  cd "${installDir}/${helper}" || echo -e "${ERROR}Something went wrong. Check your internet connection and try again."
  makepkg -si --noconfirm
  if [ $? -ne 0 ]; then
    echo -e "${ERROR}Failed to install ${helper}.${RESET}\n"
  fi

  cd .. && rm -rf $helper
fi

if [[ ! $installOptions == *"zim-powerlevel10k"* ]]; then
  zsh=""
else
  echo -e "${NOTE}zsh and powerlevel10k will be installed.\n"
  echo -e "${NOTE}Setting up zsh, zim and powerlevel10k.\n"

  #chsh -s /usr/bin/zsh
  if ! hash zimfw 2>/dev/null; then
    curl -fsSL --create-dirs -o ~/.zim/zimfw.zsh \
      https://github.com/zimfw/zimfw/releases/latest/download/zimfw.zsh
  fi
  echo -e "${WARNING}Creating backups of your existing shell config files in {$CYAN}${HOME}${RESET} ending with ${CYAN}.bak${RESET}\n"
  rm -rf "${HOME}/.zshrc.bak" "${HOME}/.zim.bak" "${HOME}/.zimrc.bak"
  mv "$HOME/.zshrc" "$HOME/.zshrc.bak"
  mv "${HOME}/.zim" "${HOME}/.zim.bak"
  mv "${HOME}/.zimrc" "${HOME}/.zimrc.bak"

  echo debugtest
  cp -r ./zsh/* "${HOME}/"
fi

if [[ $installOptions == *"dotfiles"* ]]; then
  echo -e "${NOTE}Installing and configuring hyprland with dotfiles. Backups will be availible at ${CYAN}${HOME}/.config/${RED}config${CYAN}.bak${RESET}\n"

  ## Hyprland
  rm -rf "${HOME}/.config/hypr.bak/"
  mv "${HOME}/.config/hypr/" "${HOME}/.config/hypr.bak/"
  git clone "https://github.com/etrademark/Hyprland-Dots" "${HOME}/.config/hypr/"

  ## Waybar
  rm -rf "${HOME}/.config/waybar.bak/"
  mv "${HOME}/.config/waybar/" "${HOME}/.config/waybar.bak/"

  ## Wofi
  rm -rf "${HOME}/.config/wofi.bak/"
  mv "${HOME}/.config/wofi/" "${HOME}/.config/wofi.bak/"

  cp -r ./dotconfig/* "${HOME}/.config/"

elif [[ $installOptions == *"hyprland"* ]]; then
  echo -e "${NOTE}Installing hyprland with some additional packages.\n"
  dotfiles=""
else
  dotfiles=""
  hyprland=""
fi

if [[ ! $installOptions == *"lazyvim"* ]]; then
  lazyvim=""
else
  echo -e "${NOTE}LazyVim will be installed.\n"
  echo -e "${NOTE}Configuring LazyVim starter. Backups will be availible in ${CYAN}${HOME}/.config/nvim.bak/${RESET}\n"
  rm -rf "${HOME}/.config/nvim/"
  mv "${HOME}/.config/nvim/" "${HOME}/.config/nvim.bak/"
  git clone https://github.com/LazyVim/starter ~/.config/nvim

fi

$helper -Sy --noconfirm --needed $hyprland $dotfiles $lazyvim $zsh $asusctl
