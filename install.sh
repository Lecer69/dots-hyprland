#!/usr/bin/env bash
#
# dots-hyprland installer

set -uo pipefail

# Setup / helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="$SCRIPT_DIR/dots"
CONFIG_DIR="$HOME/.config"

# Colors
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_RED='\033[1;31m'
C_BLUE='\033[1;34m'

info() { echo -e "${C_BLUE}[INFO]${C_RESET} $*"; }
success() { echo -e "${C_GREEN}[ OK ]${C_RESET} $*"; }
warn() { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
error() { echo -e "${C_RED}[FAIL]${C_RESET} $*"; }
step() { echo -e "\n${C_BOLD}==> $*${C_RESET}"; }

confirm() {
    local prompt="$1"
    local reply

    while true; do
        read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} $prompt [y/N]: ")" reply
        case "$reply" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]|"") return 1 ;;
            *) echo "Please answer y or n." ;;
        esac
    done
}

run() {
    info "Running: $*"
    if ! "$@"; then
        error "Command failed: $*"
        return 1
    fi
}

require_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        error "Please do not run this script as root. It will call sudo when it needs to."
        exit 1
    fi
}

run_with_retry() {
    # run_with_retry <max_attempts> <command...>
    local max_attempts="$1"
    shift
    local attempt=1

    while (( attempt <= max_attempts )); do
        info "Running (attempt $attempt/$max_attempts): $*"
        if "$@"; then
            return 0
        fi
        warn "Command failed (attempt $attempt/$max_attempts): $*"
        ((attempt++))
        if (( attempt <= max_attempts )); then
            info "Retrying in 3 seconds..."
            sleep 3
        fi
    done

    error "Command failed after $max_attempts attempts: $*"
    return 1
}

# Package lists
PACMAN_PACKAGES=(
    polkit wget zenity fastfetch fish kitty sddm xorg-server dolphin btop
    hyprland hyprpaper hyprpicker hyprlock hypridle hyprpwcenter hyprshot
    playerctl 7zip nvim nethogs starship bluez bluedevil bluez-qt bluez-utils
    zip unzip power-profiles-daemon xdg-desktop-portal xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk xdg-desktop-portal-kde pipewire pipewire-alsa
    pipewire-audio pipewire-jack pipewire-pulse xorg-xwayland nano
    noto-fonts noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd
    ttf-dejavu pavucontrol-qt ffmpeg git base base-devel systemsettings
    qt5ct qt6ct qt5-wayland kvantum fuzzel breeze breeze-icons plasma-desktop
    grim wl-clipboard gwenview slurp plasma-nm ddcutil brightnessctl eza glu
    libqalculate cliphist gnome-system-monitor xdg-user-dirs xdotool ufw ark
)

AUR_PACKAGES=(
    snixembed
    bibata-cursor-theme-bin
    darkly-bin
)

OPTIONAL_PACKAGES=(
    nwg-displays
    firefox
    code
)

# Files/dirs inside hypr/ that should always be preserved and never overwritten
# by an update (in addition to hypr/custom, which is handled separately).
HYPR_PRESERVE_ITEMS=(
    "custom"
    "hyprpaper.conf"
    "monitors.conf"
    "monitors.lua"
    "workspaces.conf"
)

hypr_is_preserved_item() {
    # $1: basename of an item inside hypr/
    local name="$1"
    local preserved
    for preserved in "${HYPR_PRESERVE_ITEMS[@]}"; do
        if [[ "$name" == "$preserved" ]]; then
            return 0
        fi
    done
    return 1
}

# Steps
replace_dotfiles() {
    # $1 (optional): "update" -> only sync quickshell/ and hypr/ (preserving
    #                the items in HYPR_PRESERVE_ITEMS), leaving everything
    #                else in $CONFIG_DIR untouched. Default: full install,
    #                replacing everything found in dots/.
    local mode="${1:-}"

    step "Replacing dotfiles in $CONFIG_DIR"

    if [[ ! -d "$DOTS_DIR" ]]; then
        error "Could not find dots folder at: $DOTS_DIR"
        error "Make sure you're running this script from inside the cloned repo."
        exit 1
    fi

    mkdir -p "$CONFIG_DIR"

    if [[ "$mode" == "update" ]]; then
        local update_items=("quickshell" "hypr")
        local name

        for name in "${update_items[@]}"; do
            local item="$DOTS_DIR/$name"
            local target="$CONFIG_DIR/$name"

            if [[ ! -e "$item" ]]; then
                warn "dots/$name not found, skipping."
                continue
            fi

            if [[ "$name" == "hypr" ]]; then
                info "Updating hypr config (preserving: ${HYPR_PRESERVE_ITEMS[*]})"

                mkdir -p "$target"

                shopt -s dotglob nullglob
                local hypr_items=("$item"/*)
                shopt -u dotglob nullglob

                for hypr_item in "${hypr_items[@]}"; do
                    local hname
                    hname="$(basename "$hypr_item")"

                    if hypr_is_preserved_item "$hname"; then
                        info "Skipping hypr/$hname (preserved)"
                        continue
                    fi

                    local hypr_target="$target/$hname"
                    if [[ -e "$hypr_target" ]]; then
                        rm -rf "$hypr_target"
                    fi
                    cp -r "$hypr_item" "$hypr_target"
                done

                continue
            fi

            info "Updating $name config"
            if [[ -e "$target" ]]; then
                info "Removing existing $target"
                rm -rf "$target"
            fi
            info "Copying $name -> $target"
            cp -r "$item" "$target"
        done

        success "Dotfiles updated (quickshell, hypr)."
    else
        shopt -s dotglob nullglob
        local items=("$DOTS_DIR"/*)
        shopt -u dotglob nullglob

        if [[ ${#items[@]} -eq 0 ]]; then
            warn "dots/ folder is empty, nothing to copy."
            return
        fi

        for item in "${items[@]}"; do
            local name
            name="$(basename "$item")"
            local target="$CONFIG_DIR/$name"

            if [[ -e "$target" ]]; then
                info "Removing existing $target"
                rm -rf "$target"
            fi

            info "Copying $name -> $target"
            cp -r "$item" "$target"
        done

        success "Dotfiles installed."
    fi

    if command -v hyprctl >/dev/null 2>&1; then
        info "Reloading Hyprland config"
        run hyprctl reload
    else
        info "hyprctl not found (Hyprland not installed yet), skipping reload."
    fi
}

run_pre_commands() {
    step "Running update commands"
    run_with_retry 10 sudo pacman -Syu
}

install_pacman_packages() {
    step "Installing pacman packages"

    run_with_retry 10 sudo pacman -S --needed "${PACMAN_PACKAGES[@]}"
}

run_after_package_commands() {
    step "Running essentials commands"

    run xdg-user-dirs-update
    run fc-cache -fv

    if command -v nethogs >/dev/null 2>&1; then
        run sudo setcap cap_net_raw,cap_net_admin+ep "$(command -v nethogs)"
    else
        warn "nethogs not found, skipping setcap step."
    fi

    info "Cloning NvChad starter config into ~/.config/nvim"
    if [[ -d "$HOME/.config/nvim" ]]; then
        warn "$HOME/.config/nvim already exists, removing it first."
        rm -rf "$HOME/.config/nvim"
    fi
    (cd /tmp && run git clone https://github.com/NvChad/starter "$HOME/.config/nvim")
}

install_yay() {
    step "Installing yay (AUR helper)"

    if command -v yay >/dev/null 2>&1; then
        info "yay is already installed, skipping build."
        return
    fi

    (
        cd /tmp || exit 1
        rm -rf yay
        git clone https://aur.archlinux.org/yay.git
        cd yay || exit 1
        makepkg -si
    )

    if ! command -v yay >/dev/null 2>&1; then
        error "yay installation failed."
        exit 1
    fi
    success "yay installed."
}

install_aur_packages() {
    step "Installing AUR packages"

    install_yay

    info "Installing quickshell-git"
    run_with_retry 10 yay -S --needed --rebuild quickshell-git

    info "Installing remaining AUR packages"
    run_with_retry 10 yay -S --needed "${AUR_PACKAGES[@]}"
}

do_systemctl() {
    step "Enabling services"

    run sudo systemctl enable --now ufw
    run sudo ufw enable

    run sudo systemctl enable --now power-profiles-daemon.service

    if confirm "Enable bluetooth.service now?"; then
        run sudo systemctl enable --now bluetooth.service
    else
        info "Skipping bluetooth.service."
    fi

    run sudo systemctl enable sddm
}

setup_sddm() {
    step "SDDM autologin setup"

    if ! confirm "Do you want to configure SDDM autologin?"; then
        info "Skipping SDDM autologin setup."
        return
    fi

    local default_user="$USER"
    local sddm_user
    read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} Username for autologin [$default_user]: ")" sddm_user
    sddm_user="${sddm_user:-$default_user}"

    run sudo mkdir -p /etc/sddm.conf.d

    local conf_file="/etc/sddm.conf.d/autologin.conf"
    info "Creating $conf_file"

    sudo tee "$conf_file" >/dev/null <<EOF
[Autologin]
User=$sddm_user
Session=hyprland
EOF

    success "SDDM autologin configured for user: $sddm_user"
}

run_last_commands() {
    step "Running theme settings commands"

    run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark'
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    run gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic'
    run gsettings set org.gnome.desktop.interface cursor-size 24
}

install_custom_commands() {
    step "Installing custom commands"

    local src="$SCRIPT_DIR/extra/lis"
    local dest_dir="$HOME/.local/bin"

    if [[ ! -e "$src" ]]; then
        warn "extra/lis not found at $src, skipping."
        return
    fi

    mkdir -p "$dest_dir"

    local dest="$dest_dir/lis"
    if [[ -e "$dest" ]]; then
        info "Removing existing $dest"
        rm -rf "$dest"
    fi

    info "Copying extra/lis -> $dest"
    cp -r "$src" "$dest"
    chmod +x "$dest" 2>/dev/null || true

    success "Custom commands installed."
}

install_optional_packages() {
    step "Optional packages"

    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
        if confirm "Install optional package '$pkg'?"; then
            run_with_retry 10 sudo pacman -S --needed "$pkg"
        else
            info "Skipping $pkg."
        fi
    done
}

do_install() {
    echo -e "${C_BOLD}This will replace your existing dotfiles in ~/.config with the ones from this repo.${C_RESET}"
    if ! confirm "Are you sure you want to continue with the installation?"; then
        info "Installation cancelled."
        exit 0
    fi

    replace_dotfiles
    run_pre_commands
    install_pacman_packages
    run_after_package_commands
    install_aur_packages
    do_systemctl
    setup_sddm
    run_last_commands
    install_custom_commands
    install_optional_packages

    echo
    success "Installation done!"
    if confirm "Reboot now?"; then
        sudo reboot
    else
        info "Remember to reboot later for all changes to take effect."
    fi
}

# Update path
do_update() {
    step "Updating dots-hyprland"

    echo -e "${C_BOLD}This will update quickshell and hypr configs in ~/.config (hypr/custom, hyprpaper.conf, monitors.conf, monitors.lua, and workspaces.conf will be preserved).${C_RESET}"
    if ! confirm "Continue with the update?"; then
        info "Update cancelled."
        exit 0
    fi

    replace_dotfiles "update"
    install_custom_commands

    echo
    success "Update done!"
}

# Entry point
main() {
    require_not_root

    echo -e "${C_BOLD}${C_GREEN}Welcome!${C_RESET} This script will install ${C_BOLD}dots-hyprland${C_RESET} on your system."
    echo

    while true; do
        read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} Do you want to [i]nstall or [u]pdate? ")" choice
        case "$choice" in
            [Ii]|[Ii][Nn][Ss][Tt][Aa][Ll][Ll])
                do_install
                break
                ;;
            [Uu]|[Uu][Pp][Dd][Aa][Tt][Ee])
                do_update
                break
                ;;
            *)
                echo "Please enter 'i' for install or 'u' for update."
                ;;
        esac
    done
}

main "$@"
