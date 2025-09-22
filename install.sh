#!/bin/bash

### Variables
installDir="./output"
mkdir -p "$installDir/logs"

zsh="zsh"
hyprland="hyprland noto-fonts noto-fonts-cjk kitty"
dotfiles="swaync rofi-wayland wofi wl-clipboard thunar blueman networkmanager ttf-jetbrains-mono-nerd ttf-font-awesome network-manager-applet pavucontrol alsa-firmware cava waybar swww"

# Dev
# Let me know if you have any packages for me to add here
lazyvim="unzip curl wget neovim nodejs npm ripgrep stylua lua51 luarocks hererocks fd lazygit fzf ghostscript shfmt ast-grep nix cargo"
c="gcc gdb glibc"
golang="go delve"
rust="rustup cargo"
jdk="jdk-openjdk"
python="python pip"

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
IMPORTANT=" - ${RESET}[${CYAN}IMPORTANT${RESET}]${YELLOW} "
COMMAND="\e[90m"
echo -e "${WARNING}This script is still in development. Please use it with caution.${RESET}\n${IMPORTANT}All back-upped configurations ending with .bak will be removed if this script is in use of it as it moves all old config to it and overwrites the old ones."

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

installOptions=$(whiptail --title "Hyprland-Dots install script" --checklist "Choose options to install or configure" 15 100 5 \
  "zim-powerlevel10k" "Configure and change shell to zsh (+ zim) with powerlevel10k theming" off \
  "hyprland" "Plain Hyprland without dotfiles (unless previously configured)" off \
  "dotfiles" "Configure Hyprland with etrademark's dotfiles" off \
  "developer" "Select some additional programming languages and developer tools" off \
  2>&1 >/dev/tty)
cancel

if [[ $installOptions == *"developer"* ]]; then
  dev=$(whiptail --title "development tools" --checklist "Checklist" 25 80 10 \
    "lazyvim" "Install LazyVim and NeoVim text editor/\"ide\" (command: nvim)" off \
    "c/c++" "C and C++ with GCC compiler and GDB debugger" off \
    "rust" "Install Rust stable with rustup" off \
    "golang" "Go with Delve debugger" off \
    "jdk" "Installation of jdk (jdk-openjdk) with JDB as debugger" off \
    "python" "Install python with virtualenvs and pip" off \
    2>&1 >/dev/tty)
  cancel

  ### --- LazyVim --- ###
  if [[ ! $installOptions == *"lazyvim"* ]]; then
    lazyvim=""
  else
    echo -e "${NOTE}LazyVim will be installed.\n"
    echo -e "${NOTE}Configuring LazyVim starter. Backups will be availible in ${CYAN}${HOME}/.config/nvim.bak/${RESET}\n"
    rm -rf "${HOME}/.config/nvim/"
    mv "${HOME}/.config/nvim/" "${HOME}/.config/nvim.bak/"
    git clone https://github.com/LazyVim/starter ~/.config/nvim
  fi

  ### --- C/C++ --- ###
  if [[ ! $installOptions == *"c/c++"* ]]; then
    c=""
  fi

  ### --- Rust --- ###
  if [[ ! $installOptions == *"rust"* ]]; then
    rust=""
  fi

  ### --- Go --- ###
  if [[ ! $installOptions == *"golang"* ]]; then
    golang=""
  fi

  ### --- JDK --- ###
  if [[ ! $installOptions == *"jdk"* ]]; then
    jdk=""
  fi

  ### --- python --- ###
  if [[ ! $installOptions == *"python"* ]]; then
    python=""
  fi

  ### -------------- ###
  devel="${c} ${rust} ${golang} ${jdk} ${python}"
fi

function rog_check() {
  if [[ $(hostnamectl) == *"ASUSTeK COMPUTER INC."* ]]; then
    if [[ $(hostnamectl) == *[Ll]"aptop"* ]]; then
      if whiptail --title "ROG" --yesno "You seem to have an ASUS device.\nDo you want to install asus-linux and supergfxctl (recommended for ROG and TUF laptops)?" 10 50; then
        return 1
      else
        echo -e "${NOTE}Installing asus-linux and supergfxctl (recommended for ROG and TUF laptops).\n"
        return 0
      fi
    fi
  fi
  return 1
}

if ! rog_check; then
  asusctl=""
fi

echo -e "${NOTE}Installing required packages and setting up permissions.\n"
sudo pacman -Sy --noconfirm --needed base-devel git curl

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
  cp -r ./zsh/. "${HOME}/"
fi

if [[ $installOptions == *"dotfiles"* ]]; then
  echo -e "${NOTE}Installing and configuring hyprland with dotfiles. Backups will be availible at ${CYAN}${HOME}/.config/${RED}config${CYAN}.bak${RESET}\n"

  ## Hyprland
  rm -rf "${HOME}/.config/hypr.bak/"
  mv "${HOME}/.config/hypr/" "${HOME}/.config/hypr.bak/"
  git clone "https://github.com/etrademark/Hyprland-Dots" "${HOME}/.config/hypr/"
  cd "${HOME}/.config/hypr/"
  git checkout 608a8ac9d5a59accdb462a2825983cb95faaeb94

  ## Waybar
  rm -rf "${HOME}/.config/waybar.bak/"
  mv "${HOME}/.config/waybar/" "${HOME}/.config/waybar.bak/"

  ## Wofi
  rm -rf "${HOME}/.config/wofi.bak/"
  mv "${HOME}/.config/wofi/" "${HOME}/.config/wofi.bak/"

  cp -r ./dotconfig/* "${HOME}/.config/"

  cp -pr ./misc/Wallpapers/* "${HOME}/Pictures/Wallpapers/"
  swww-daemon && swww img "${HOME}/Pictures/Wallpapers/wallpaper.jpg" || echo -e "${ERROR}Something went wrong while setting the wallpaper. Try again when you're in Hyprland with ${COMMAND}swww img ${HOME}/Pictures/Wallpapers/wallpaper.jpg${RESET}\n"
elif [[ $installOptions == *"hyprland"* ]]; then
  echo -e "${NOTE}Installing hyprland with some additional packages.\n"
  dotfiles=""
else
  dotfiles=""
  hyprland=""
fi

$helper -Sy --noconfirm --needed $hyprland $dotfiles $lazyvim $zsh $asusctl $devel

if [[ $dev == *"rust"* ]]; then
  rustup default stable || echo -e "${ERROR}Failed to run rustup. Perhaps you already have the rust package installed?${RESET}\n"
fi
