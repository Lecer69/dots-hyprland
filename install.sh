#!/usr/bin/env bash
#
# dots-hyprland installer

set -uo pipefail

# Flags
MODE=""
ASSUME_YES=0
SKIP_UPDATE=0
SKIP_PACKAGES=0
SKIP_QUICKSHELL=0
SKIP_BACKUP=0

print_help() {
    cat <<EOF
dots-hyprland installer

Usage: $(basename "${BASH_SOURCE[0]}") [OPTIONS]

Without --install, --update or --backup, you will be prompted to choose
[i]nstall or [u]pdate after launch.

Options:
  --install           Install the dots and the packages they need
  --update            Update the quickshell and hypr configs, and offer to
                      install packages the dots need that you don't have
  --backup            Only back up existing config (everything an install
                      replaces) and exit, no install/update
  -y, --yes           Don't ask anything: take the default answer (the capital
                      letter) to every question, and run pacman and the AUR
                      helper with --noconfirm
  --skip-update       Install packages without updating the system (not
                      recommended: partial upgrades can break your system)
  --no-packages       Skip all pacman/AUR package installation (implies skipping
                      the system update as well)
  --skip-quickshell   Don't install/update the quickshell config
  --skip-backup       Don't back up existing config before overwriting it (not recommended)
  -h, --help          Show this help message and exit

The package lists are in packages/. Each run's output is saved to
~/.cache/dots-hyprland/install.log.

Examples:
  $(basename "${BASH_SOURCE[0]}")                   # interactive install/update
  $(basename "${BASH_SOURCE[0]}") --update          # update, without the menu
  $(basename "${BASH_SOURCE[0]}") --install --yes   # install without any questions
  $(basename "${BASH_SOURCE[0]}") --skip-backup     # skip backup step
  $(basename "${BASH_SOURCE[0]}") --no-packages     # only sync dotfiles, no package install
  $(basename "${BASH_SOURCE[0]}") --backup          # take a backup only, don't install/update
EOF
}

set_mode() {
    if [[ -n "$MODE" && "$MODE" != "$1" ]]; then
        echo "Use only one of --install, --update and --backup." >&2
        exit 1
    fi
    MODE="$1"
}

for arg in "$@"; do
    case "$arg" in
        --install)
            set_mode install
            ;;
        --update)
            set_mode update
            ;;
        --backup)
            set_mode backup
            ;;
        -y|--yes)
            ASSUME_YES=1
            ;;
        --skip-update)
            SKIP_UPDATE=1
            ;;
        --no-packages)
            SKIP_PACKAGES=1
            ;;
        --skip-quickshell)
            SKIP_QUICKSHELL=1
            ;;
        --skip-backup)
            SKIP_BACKUP=1
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            print_help
            exit 1
            ;;
    esac
done

# Setup / helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPT_PATH="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
DOTS_DIR="$SCRIPT_DIR/dots"
PACKAGES_DIR="$SCRIPT_DIR/packages"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.dots-hyprland-backups"
# Older backups are deleted
BACKUP_KEEP=10
LOG_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/dots-hyprland"
LOG_FILE="$LOG_DIR/install.log"
# The shell's Dots Updater script, which --update runs as well
UPDATER="$DOTS_DIR/quickshell/lis/scripts/dots-update.sh"
NETHOGS_HOOK="/etc/pacman.d/hooks/dots-hyprland-nethogs.hook"

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

die() {
    error "$*"
    exit 1
}

# Steps that failed without stopping the run, listed at the end
FAILURES=()

note_failure() {
    FAILURES+=("$1")
}

# confirm <question> [y|n]: an empty answer takes the default (n when not
# given), and --yes takes it without asking
confirm() {
    local prompt="$1"
    local default="${2:-n}"
    local hint="y/N"
    local reply

    [[ "$default" == y ]] && hint="Y/n"

    if [[ "$ASSUME_YES" -eq 1 ]]; then
        echo -e "${C_YELLOW}[?]${C_RESET} $prompt [$hint]: $default (--yes)"
        [[ "$default" == y ]]
        return
    fi

    while true; do
        read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} $prompt [$hint]: ")" reply
        case "${reply:-$default}" in
            [Yy]|[Yy][Ee][Ss]) return 0 ;;
            [Nn]|[Nn][Oo]) return 1 ;;
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

# Runs a command up to 3 times, asking before each retry: a failure can be a
# network error, but also a declined prompt or a wrong password
run_with_retry() {
    local attempt

    for attempt in 1 2 3; do
        run "$@" && return 0
        (( attempt < 3 )) || break
        confirm "Try again? (attempt $((attempt + 1))/3)" y || break
        [[ "$ASSUME_YES" -eq 1 ]] && sleep 3
    done

    return 1
}

require_not_root() {
    if [[ "$EUID" -eq 0 ]]; then
        error "Please do not run this script as root. It will call sudo when it needs to."
        exit 1
    fi
}

SUDO_KEEPALIVE_PID=""

# Asks for the sudo password once, then keeps sudo's timestamp fresh until the
# script exits, so a long build doesn't stop at a password prompt
ensure_sudo() {
    [[ -n "$SUDO_KEEPALIVE_PID" ]] && return 0

    sudo -v || die "This step needs sudo."
    # Without a terminal, or script(1) would wait for its sleep at the end
    while kill -0 "$$" 2>/dev/null; do
        sudo -n -v
        sleep 50
    done </dev/null >/dev/null 2>&1 &
    SUDO_KEEPALIVE_PID=$!
}

stop_sudo_keepalive() {
    if [[ -n "$SUDO_KEEPALIVE_PID" ]]; then
        kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
    fi
}

trap stop_sudo_keepalive EXIT

# Saves this run's output to $LOG_FILE by running the script again inside
# script(1), which keeps a terminal between pacman/yay and the screen, so their
# prompts and progress bars still work
start_logging() {
    [[ -z "${DOTS_INSTALL_LOGGING:-}" ]] || return 0
    [[ -t 0 && -t 1 ]] || return 0
    # An older script(1) can't run a command given after --
    [[ "$(script --help 2>/dev/null)" == *"-- <command>"* ]] || return 0
    mkdir -p "$LOG_DIR" 2>/dev/null || return 0

    export DOTS_INSTALL_LOGGING=1
    exec script --quiet --return --flush "$LOG_FILE" -- "$BASH" "$SCRIPT_PATH" "$@"
}

preflight() {
    require_not_root

    if ! command -v pacman >/dev/null 2>&1; then
        die "pacman not found. dots-hyprland only works on Arch Linux and Arch-based distros."
    fi

    if [[ ! -d "$DOTS_DIR" ]]; then
        error "Could not find dots folder at: $DOTS_DIR"
        die "Make sure you're running this script from inside the cloned repo."
    fi
}

# Whether this runs inside a Hyprland session, which hyprctl needs
in_hyprland() {
    [[ -n "${HYPRLAND_INSTANCE_SIGNATURE:-}" ]] && command -v hyprctl >/dev/null 2>&1
}

# Package lists
PACMAN_PACKAGES=()
AUR_PACKAGES=()
OPTIONAL_PACKAGES=()

# Prints the names in a packages/*.txt list: one per line, # starts a comment
read_package_list() {
    local line
    local -a words

    while IFS= read -r line || [[ -n "$line" ]]; do
        read -ra words <<<"${line%%#*}"
        [[ ${#words[@]} -eq 0 ]] || printf '%s\n' "${words[@]}"
    done <"$1"
}

load_package_lists() {
    local list
    for list in pacman aur optional; do
        if [[ ! -f "$PACKAGES_DIR/$list.txt" ]]; then
            die "Could not find $PACKAGES_DIR/$list.txt"
        fi
    done

    mapfile -t PACMAN_PACKAGES < <(read_package_list "$PACKAGES_DIR/pacman.txt")
    mapfile -t AUR_PACKAGES < <(read_package_list "$PACKAGES_DIR/aur.txt")
    mapfile -t OPTIONAL_PACKAGES < <(read_package_list "$PACKAGES_DIR/optional.txt")
}

# Prints which of the given packages aren't installed. pacman -T counts a
# package that provides the name, so quickshell-git stands in for quickshell
missing_packages() {
    [[ $# -gt 0 ]] || return 0
    pacman -T "$@"
    return 0
}

# Files/dirs inside hypr/ that updates never overwrite (dots-update.sh has the
# same list), and that an install keeps if you choose to
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

# "hypr/custom, hypr/hyprpaper.conf, ..." for messages
hypr_preserved_text() {
    local text
    text="$(printf 'hypr/%s, ' "${HYPR_PRESERVE_ITEMS[@]}")"
    echo "${text%, }"
}

# Questions, all asked before the install starts so it can run on its own
PRESERVE_HYPR=0
CHOSEN_OPTIONAL=()
SYSTEM_UNITS=()
USER_UNITS=()
USE_SDDM=0
AUTOLOGIN_USER=""

ask_preserve_hypr() {
    local name
    local -a found=()

    for name in "${HYPR_PRESERVE_ITEMS[@]}"; do
        if [[ -e "$CONFIG_DIR/hypr/$name" ]]; then
            found+=("hypr/$name")
        fi
    done
    [[ ${#found[@]} -gt 0 ]] || return 0

    local list
    list="$(printf '%s, ' "${found[@]}")"
    if confirm "Keep your existing ${list%, }? Say no if they're from a different setup." y; then
        PRESERVE_HYPR=1
    fi
}

ask_optional_packages() {
    [[ "$SKIP_PACKAGES" -eq 0 ]] || return 0

    local pkg
    for pkg in "${OPTIONAL_PACKAGES[@]}"; do
        if pacman -T "$pkg" >/dev/null; then
            info "Optional package '$pkg' is already installed."
        elif confirm "Install optional package '$pkg'?"; then
            CHOSEN_OPTIONAL+=("$pkg")
        fi
    done
}

# ask_service <unit> <question> [user]: queues the unit to be enabled
ask_service() {
    local unit="$1"
    local question="$2"
    local scope="${3:-system}"
    local -a systemctl_cmd=(systemctl)

    [[ "$scope" == user ]] && systemctl_cmd+=(--user)

    if "${systemctl_cmd[@]}" is-enabled --quiet "$unit" 2>/dev/null; then
        info "$unit is already enabled."
        return
    fi

    if confirm "$question" y; then
        if [[ "$scope" == user ]]; then
            USER_UNITS+=("$unit")
        else
            SYSTEM_UNITS+=("$unit")
        fi
    fi
}

ask_network_manager() {
    if systemctl is-enabled --quiet NetworkManager.service 2>/dev/null; then
        info "NetworkManager.service is already enabled."
        return
    fi

    local default=y
    local unit
    local -a others=()
    for unit in systemd-networkd iwd connman dhcpcd; do
        if systemctl is-active --quiet "$unit.service" 2>/dev/null; then
            others+=("$unit")
        fi
    done

    if [[ ${#others[@]} -gt 0 ]]; then
        warn "${others[*]} runs your network now, and NetworkManager next to it can break your connection. Disable it first if you switch."
        default=n
    fi

    if confirm "Enable NetworkManager.service (the shell's network panel needs it)?" "$default"; then
        SYSTEM_UNITS+=("NetworkManager.service")
    fi
}

ask_sddm() {
    local current
    current="$(readlink /etc/systemd/system/display-manager.service 2>/dev/null)"
    current="$(basename "${current:-none}" .service)"

    case "$current" in
        sddm)
            info "SDDM is already your display manager."
            USE_SDDM=1
            ;;
        none)
            if confirm "Enable sddm (display manager)?" y; then
                SYSTEM_UNITS+=("sddm.service")
                USE_SDDM=1
            fi
            ;;
        *)
            info "Your display manager is $current, leaving it. To switch, disable it and enable sddm."
            ;;
    esac
}

ask_autologin() {
    [[ "$USE_SDDM" -eq 1 ]] || return 0
    confirm "Do you want to configure SDDM autologin?" || return 0

    local name
    while true; do
        read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} Username for autologin [$USER]: ")" name
        name="${name:-$USER}"
        if id -u "$name" >/dev/null 2>&1; then
            break
        fi
        echo "There is no user named $name."
    done
    AUTOLOGIN_USER="$name"
}

ask_install_questions() {
    step "Questions"
    info "Answer these first, so the install doesn't stop for them later."

    ask_preserve_hypr
    ask_optional_packages
    ask_service ufw.service "Enable ufw (firewall)?"
    ask_service ydotool.service "Enable ydotool (some keybinds use it)?" user
    ask_service power-profiles-daemon.service "Enable power-profiles-daemon.service?"
    ask_service systemd-oomd.service "Enable systemd-oomd.service?"
    ask_service bluetooth.service "Enable bluetooth.service?"
    ask_network_manager
    ask_sddm
    ask_autologin
}

# Backup
# Deletes all but the newest $BACKUP_KEEP backups. Only touches files named like
# the ones made here and by dots-update.sh, which sort oldest first
prune_backups() {
    local LC_ALL=C
    local -a backups

    shopt -s nullglob
    backups=("$BACKUP_DIR"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].zip)
    shopt -u nullglob

    local excess=$(( ${#backups[@]} - BACKUP_KEEP ))
    (( excess > 0 )) || return 0

    if rm -f -- "${backups[@]:0:excess}"; then
        info "Deleted $excess old backup(s), keeping the newest $BACKUP_KEEP."
    fi
}

# Zips everything in ~/.config that an install replaces
backup_dotfiles() {
    step "Backing up existing config"

    if [[ "$SKIP_BACKUP" -eq 1 ]]; then
        warn "Skipping backup (--skip-backup passed). This is not recommended."
        return 0
    fi

    if ! command -v zip >/dev/null 2>&1; then
        warn "zip is not installed. Attempting to install it now..."
        ensure_sudo
        if sudo pacman -S --needed --noconfirm zip; then
            success "zip installed."
        else
            error "Could not install zip automatically."
            die "Install zip manually, or re-run with --skip-backup to proceed without one (not recommended)."
        fi
    fi

    local item name
    local -a to_backup=()
    shopt -s dotglob nullglob
    for item in "$DOTS_DIR"/*; do
        name="$(basename "$item")"
        if [[ "$name" == "quickshell" && "$SKIP_QUICKSHELL" -eq 1 ]]; then
            continue
        fi
        if [[ -e "$CONFIG_DIR/$name" ]]; then
            to_backup+=("$name")
        fi
    done
    shopt -u dotglob nullglob

    if [[ ${#to_backup[@]} -eq 0 ]]; then
        info "Nothing existing to back up, skipping."
        return 0
    fi

    mkdir -p "$BACKUP_DIR" || die "Could not create backup directory: $BACKUP_DIR"

    local zip_path
    zip_path="$BACKUP_DIR/$(date +%Y-%m-%d_%H-%M-%S).zip"
    info "Backing up ${to_backup[*]} to $zip_path"
    if ! (cd "$CONFIG_DIR" && zip -r -q "$zip_path" "${to_backup[@]}"); then
        rm -f "$zip_path"
        die "Failed to create backup zip: $zip_path"
    fi

    success "Backup created: $zip_path"
    prune_backups
}

# Packages
# pacman_install <package...>: installs them from the repos, in one transaction
# with a full system update unless --skip-update was passed
pacman_install() {
    local -a flags=(--needed)
    [[ "$ASSUME_YES" -eq 1 ]] && flags+=(--noconfirm)

    if [[ "$SKIP_UPDATE" -eq 1 ]]; then
        if [[ $# -eq 0 ]]; then
            success "All packages are already installed."
            return 0
        fi
        warn "Not updating the system (--skip-update passed). This is not recommended and may cause package conflicts later."
        ensure_sudo
        run_with_retry sudo pacman -S "${flags[@]}" "$@"
        return
    fi

    # One transaction: a single prompt, and nothing new gets installed next to
    # outdated libraries
    ensure_sudo
    run_with_retry sudo pacman -Syu "${flags[@]}" "$@"
}

install_pacman_packages() {
    step "Installing pacman packages"

    if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
        warn "Skipping pacman package installation (--no-packages passed)."
        return
    fi

    local -a targets
    mapfile -t targets < <(missing_packages "${PACMAN_PACKAGES[@]}" "${CHOSEN_OPTIONAL[@]}")
    if [[ ${#targets[@]} -gt 0 ]]; then
        info "Not installed yet: ${targets[*]}"
    fi

    pacman_install "${targets[@]}" || die "Installing packages failed. Fix the error above and run the installer again."
}

AUR_HELPER=""

# Uses yay or paru, whichever is installed, or installs yay-bin, which is
# prebuilt, so it doesn't need the Go toolchain
install_aur_helper() {
    local helper
    for helper in yay paru; do
        if command -v "$helper" >/dev/null 2>&1; then
            AUR_HELPER="$helper"
            info "Using $helper for AUR packages."
            return 0
        fi
    done

    info "Installing yay (AUR helper)"
    local -a flags=(--needed)
    [[ "$ASSUME_YES" -eq 1 ]] && flags+=(--noconfirm)

    local build_dir
    build_dir="$(mktemp -d)" || return 1
    ensure_sudo
    run git clone --depth 1 https://aur.archlinux.org/yay-bin.git "$build_dir/yay-bin" \
        && (cd "$build_dir/yay-bin" && run makepkg -si "${flags[@]}")
    rm -rf "$build_dir"

    if ! command -v yay >/dev/null 2>&1; then
        error "yay installation failed."
        return 1
    fi
    AUR_HELPER="yay"
    success "yay installed."
}

# aur_install <package...>
aur_install() {
    if [[ $# -eq 0 ]]; then
        success "All AUR packages are already installed."
        return 0
    fi

    install_aur_helper || return 1

    local -a flags=(--needed)
    [[ "$ASSUME_YES" -eq 1 ]] && flags+=(--noconfirm)
    ensure_sudo
    run_with_retry "$AUR_HELPER" -S "${flags[@]}" "$@"
}

install_aur_packages() {
    step "Installing AUR packages"

    if [[ "$SKIP_PACKAGES" -eq 1 ]]; then
        warn "Skipping AUR helper (yay) and AUR package installation (--no-packages passed)."
        return
    fi

    local -a targets
    mapfile -t targets < <(missing_packages "${AUR_PACKAGES[@]}")
    if [[ ${#targets[@]} -gt 0 ]]; then
        info "Not installed yet: ${targets[*]}"
    fi

    aur_install "${targets[@]}" || die "Installing AUR packages failed. Fix the error above and run the installer again."
}

# The internet usage panel runs nethogs as your user, which needs capabilities
# that pacman drops whenever it installs nethogs. This hook adds them back
nethogs_hook() {
    cat <<'EOF'
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = nethogs

[Action]
Description = Letting nethogs capture traffic without root (dots-hyprland)...
When = PostTransaction
Exec = /usr/bin/setcap cap_net_raw,cap_net_admin+ep /usr/bin/nethogs
EOF
}

setup_nethogs() {
    step "Setting up nethogs"

    local nethogs
    if ! nethogs="$(command -v nethogs)"; then
        warn "nethogs not found, skipping."
        return
    fi

    ensure_sudo
    if [[ ! -f "$NETHOGS_HOOK" ]]; then
        info "Creating $NETHOGS_HOOK"
        if ! { sudo mkdir -p "$(dirname "$NETHOGS_HOOK")" && nethogs_hook | sudo tee "$NETHOGS_HOOK" >/dev/null; }; then
            error "Could not create $NETHOGS_HOOK"
            note_failure "Creating the nethogs pacman hook"
        fi
    fi

    run sudo setcap cap_net_raw,cap_net_admin+ep "$nethogs" || note_failure "Giving nethogs its capabilities (setcap)"
}

# Dotfiles
KEPT_HYPRPAPER=0

# replace_item <source> <target>: replaces target with a copy of source
replace_item() {
    local source="$1"
    local target="$2"

    if [[ -e "$target" || -L "$target" ]]; then
        if ! rm -rf "$target" || [[ -e "$target" || -L "$target" ]]; then
            die "Failed to remove existing $target, aborting to avoid nesting copy."
        fi
    fi
    cp -r "$source" "$target" || die "Failed to copy $source to $target."
}

# Copies dots/hypr over ~/.config/hypr, keeping the preserved items it has
install_hypr_preserving() {
    local source="$1"
    local target="$2"
    local item name

    info "Updating hypr config"
    mkdir -p "$target" || die "Could not create $target"

    shopt -s dotglob nullglob
    local -a items=("$source"/*)
    shopt -u dotglob nullglob

    for item in "${items[@]}"; do
        name="$(basename "$item")"
        if hypr_is_preserved_item "$name" && [[ -e "$target/$name" ]]; then
            info "Keeping hypr/$name"
            [[ "$name" == "hyprpaper.conf" ]] && KEPT_HYPRPAPER=1
            continue
        fi
        replace_item "$item" "$target/$name"
    done
}

# The names Hyprland gives this machine's connected monitors: the DRM connector
# names (card1-eDP-1 is eDP-1). Read from sysfs, so Hyprland needn't be running
connected_monitors() {
    local status connector
    for status in /sys/class/drm/card*-*/status; do
        [[ "$(cat "$status" 2>/dev/null)" == "connected" ]] || continue
        connector="$(basename "$(dirname "$status")")"
        echo "${connector#card*-}"
    done
}

# Repeats hyprpaper.conf's wallpaper block for each connected monitor. The shell
# starts hyprpaper, and changes the blocks from its displays panel
fix_hyprpaper_monitors() {
    local hyprpaper_conf="$CONFIG_DIR/hypr/hyprpaper.conf"
    [[ -f "$hyprpaper_conf" ]] || return 0

    local -a monitors
    mapfile -t monitors < <(connected_monitors)
    if [[ ${#monitors[@]} -eq 0 ]]; then
        warn "Could not detect a connected monitor, leaving hyprpaper.conf monitor as-is."
        return 0
    fi

    info "Setting hyprpaper.conf's wallpaper for: ${monitors[*]}"
    local updated
    if updated="$(awk -v monitors="${monitors[*]}" '
        BEGIN { count = split(monitors, names, " ") }
        !done && /^[[:space:]]*wallpaper[[:space:]]*[{]/ { inside = 1 }
        inside {
            block[++lines] = $0
            if ($0 ~ /^[[:space:]]*[}]/) {
                inside = 0
                done = 1
                for (m = 1; m <= count; m++) {
                    if (m > 1) print ""
                    for (i = 1; i <= lines; i++) {
                        line = block[i]
                        if (line ~ /^[[:space:]]*monitor[[:space:]]*=/) {
                            match(line, /^[[:space:]]*/)
                            line = substr(line, 1, RLENGTH) "monitor = " names[m]
                        }
                        print line
                    }
                }
            }
            next
        }
        { print }
    ' "$hyprpaper_conf")" && printf '%s\n' "$updated" >"$hyprpaper_conf"; then
        success "hyprpaper.conf monitor updated to ${monitors[*]}."
    else
        warn "Failed to update hyprpaper.conf monitor, leaving as-is."
        note_failure "Setting hyprpaper.conf's monitors"
    fi
}

replace_dotfiles() {
    backup_dotfiles

    step "Replacing dotfiles in $CONFIG_DIR"

    mkdir -p "$CONFIG_DIR" || die "Could not create $CONFIG_DIR"

    shopt -s dotglob nullglob
    local -a items=("$DOTS_DIR"/*)
    shopt -u dotglob nullglob

    if [[ ${#items[@]} -eq 0 ]]; then
        warn "dots/ folder is empty, nothing to copy."
        return
    fi

    local item name target
    for item in "${items[@]}"; do
        name="$(basename "$item")"
        target="$CONFIG_DIR/$name"

        if [[ "$name" == "quickshell" && "$SKIP_QUICKSHELL" -eq 1 ]]; then
            info "Skipping quickshell (--skip-quickshell passed)"
            continue
        fi

        if [[ "$name" == "hypr" && "$PRESERVE_HYPR" -eq 1 && -d "$target" ]]; then
            install_hypr_preserving "$item" "$target"
            continue
        fi

        if [[ -e "$target" || -L "$target" ]]; then
            info "Removing existing $target"
        fi
        info "Copying $name -> $target"
        replace_item "$item" "$target"
    done

    if [[ "$KEPT_HYPRPAPER" -eq 0 ]]; then
        fix_hyprpaper_monitors
    fi

    success "Dotfiles installed."
}

install_custom_commands() {
    step "Installing custom commands"

    local src="$SCRIPT_DIR/extra/lis"
    local dest_dir="$HOME/.local/bin"
    local dest="$dest_dir/lis"

    if [[ ! -e "$src" ]]; then
        warn "extra/lis not found at $src, skipping."
        return
    fi

    info "Copying extra/lis -> $dest"
    if mkdir -p "$dest_dir" && rm -rf "$dest" && cp -r "$src" "$dest"; then
        chmod +x "$dest" 2>/dev/null || true
        success "Custom commands installed."
    else
        error "Could not install $dest"
        note_failure "Installing the lis command"
    fi
}

run_after_package_commands() {
    step "Running essentials commands"

    run xdg-user-dirs-update || note_failure "Creating the user folders (xdg-user-dirs-update)"
    run fc-cache -f || note_failure "Refreshing the font cache (fc-cache)"
}

enable_services() {
    step "Enabling services"

    if [[ $(( ${#SYSTEM_UNITS[@]} + ${#USER_UNITS[@]} )) -eq 0 ]]; then
        info "No services to enable."
        return
    fi

    local unit
    for unit in "${SYSTEM_UNITS[@]}"; do
        ensure_sudo
        if [[ "$unit" == "sddm.service" ]]; then
            # Only from the next boot: starting it now would take over the screen
            run sudo systemctl enable "$unit" || note_failure "Enabling $unit"
        else
            run sudo systemctl enable --now "$unit" || note_failure "Enabling $unit"
        fi

        if [[ "$unit" == "ufw.service" ]]; then
            run sudo ufw enable || note_failure "Turning on ufw"
        fi
    done

    for unit in "${USER_UNITS[@]}"; do
        run systemctl --user enable --now "$unit" || note_failure "Enabling $unit (user service)"
    done
}

setup_sddm_autologin() {
    [[ -n "$AUTOLOGIN_USER" ]] || return 0

    step "SDDM autologin setup"

    local conf_file="/etc/sddm.conf.d/autologin.conf"
    info "Creating $conf_file"

    ensure_sudo
    if sudo mkdir -p /etc/sddm.conf.d && sudo tee "$conf_file" >/dev/null <<EOF
[Autologin]
User=$AUTOLOGIN_USER
Session=hyprland
Relogin=true
EOF
    then
        success "SDDM autologin configured for user: $AUTOLOGIN_USER"
    else
        error "Could not create $conf_file"
        note_failure "Setting up SDDM autologin"
    fi
}

apply_theme() {
    step "Running theme settings commands"

    local failed=0
    run gsettings set org.gnome.desktop.interface gtk-theme 'adw-gtk3-dark' || failed=1
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark' || failed=1
    run gsettings set org.gnome.desktop.interface cursor-theme 'Bibata-Modern-Classic' || failed=1
    run gsettings set org.gnome.desktop.interface cursor-size 24 || failed=1
    [[ "$failed" -eq 0 ]] || note_failure "Setting the GTK and cursor themes (gsettings)"

    local lis="$HOME/.local/bin/lis"
    if [[ ! -x "$lis" ]]; then
        warn "$lis not found, skipping the color scheme."
        note_failure "Generating the color scheme"
        return
    fi

    info "Generating the color scheme (output in $LOG_DIR/theme.log)"
    mkdir -p "$LOG_DIR"
    # Detached: kde-material-you-colors keeps running
    setsid -f "$lis" matugen '#FF0000' rainbow >"$LOG_DIR/theme.log" 2>&1 </dev/null
}

reload_hyprland() {
    if in_hyprland; then
        info "Reloading Hyprland config"
        run hyprctl reload || note_failure "Reloading Hyprland"
    else
        info "Not running inside Hyprland, skipping reload."
    fi
}

print_summary() {
    local what="$1"

    echo
    if [[ ${#FAILURES[@]} -gt 0 ]]; then
        warn "$what finished, but these steps failed:"
        local failure
        for failure in "${FAILURES[@]}"; do
            echo "  - $failure"
        done
    else
        success "$what done!"
    fi

    if [[ -n "${DOTS_INSTALL_LOGGING:-}" ]]; then
        info "The output of this run is saved in $LOG_FILE"
    fi
}

do_install() {
    load_package_lists

    echo -e "${C_BOLD}This will replace your existing dotfiles in ~/.config with the ones from this repo.${C_RESET}"
    if [[ "$ASSUME_YES" -eq 0 ]] && ! confirm "Are you sure you want to continue with the installation?"; then
        info "Installation cancelled."
        exit 0
    fi

    ask_install_questions

    install_pacman_packages
    install_aur_packages
    setup_nethogs
    replace_dotfiles
    install_custom_commands
    run_after_package_commands
    enable_services
    setup_sddm_autologin
    apply_theme
    reload_hyprland

    print_summary "Installation"
    if confirm "Reboot now?"; then
        sudo reboot
    else
        info "Remember to reboot later for all changes to take effect."
    fi
}

# Backup-only path
do_backup_only() {
    if [[ "$SKIP_BACKUP" -eq 1 ]]; then
        die "--backup and --skip-backup cannot be used together."
    fi

    backup_dotfiles

    echo
    success "Backup done!"
}

# Update path
# What the Dots Updater page calls dots-update.sh's steps
updater_step_label() {
    case "$1" in
        checkout) echo "Checking the files" ;;
        packages) echo "Checking packages" ;;
        backup) echo "Backing up" ;;
        hypr) echo "Updating the Hyprland config" ;;
        command) echo "Installing the lis command" ;;
        shell) echo "Updating the shell" ;;
        reload) echo "Reloading Hyprland" ;;
        *) echo "$1" ;;
    esac
}

# Updates through the shell's own updater (dots-update.sh), on this repo's files
# as they are, so updating from here and from the settings do the same
run_updater() {
    step "Updating dotfiles in $CONFIG_DIR"

    if [[ ! -f "$UPDATER" ]]; then
        die "Could not find $UPDATER"
    fi

    local backup=1
    local shell=1
    if [[ "$SKIP_BACKUP" -eq 1 ]]; then
        warn "Skipping backup (--skip-backup passed). This is not recommended."
        backup=0
    fi
    if [[ "$SKIP_QUICKSHELL" -eq 1 ]]; then
        info "Skipping quickshell (--skip-quickshell passed)"
        shell=0
    fi

    local kind name detail
    local failed=0
    # "step <name>", then "done <name> [detail]" or "fail <name> <reason>"
    while read -r kind name detail; do
        case "$kind" in
            step)
                info "$(updater_step_label "$name")..."
                ;;
            done)
                if [[ "$name" == "packages" ]]; then
                    if [[ -n "$detail" ]]; then
                        warn "Still missing: $detail"
                        note_failure "Packages still missing: $detail"
                    else
                        success "All packages are installed"
                    fi
                else
                    success "$(updater_step_label "$name")${detail:+: $detail}"
                fi
                ;;
            fail)
                if [[ "$name" == "reload" ]]; then
                    # Outside Hyprland there's nothing to reload
                    warn "Reloading Hyprland failed: $detail"
                    note_failure "Reloading Hyprland"
                else
                    error "$(updater_step_label "$name") failed: $detail"
                    failed=1
                fi
                ;;
        esac
    done < <(DOTS_UPDATE_WAIT=1 bash "$UPDATER" "$SCRIPT_DIR" - "$backup" "$shell")

    if [[ "$failed" -eq 1 ]]; then
        die "Update failed."
    fi
}

do_update() {
    load_package_lists

    step "Updating dots-hyprland"

    echo -e "${C_BOLD}This will update quickshell and hypr configs in ~/.config ($(hypr_preserved_text) will be preserved).${C_RESET}"
    if [[ "$ASSUME_YES" -eq 0 ]] && ! confirm "Continue with the update?"; then
        info "Update cancelled."
        exit 0
    fi

    local -a missing_pacman=()
    local -a missing_aur=()
    local install_missing=0
    local add_hook=0

    if [[ "$SKIP_PACKAGES" -eq 0 ]]; then
        mapfile -t missing_pacman < <(missing_packages "${PACMAN_PACKAGES[@]}")
        mapfile -t missing_aur < <(missing_packages "${AUR_PACKAGES[@]}")

        local -a all_missing=("${missing_pacman[@]}" "${missing_aur[@]}")
        if [[ ${#all_missing[@]} -gt 0 ]]; then
            warn "The dots need packages you don't have: ${all_missing[*]}"
            local question="Install them?"
            if [[ "$SKIP_UPDATE" -eq 0 && ${#missing_pacman[@]} -gt 0 ]]; then
                question="Install them? This updates the system as well (sudo pacman -Syu)."
            fi
            if confirm "$question" y; then
                install_missing=1
            fi
        fi

        if [[ ! -f "$NETHOGS_HOOK" ]] && command -v nethogs >/dev/null 2>&1; then
            if confirm "Add a pacman hook so the internet usage panel keeps working after nethogs updates?" y; then
                add_hook=1
            fi
        fi
    fi

    if [[ "$install_missing" -eq 1 ]]; then
        step "Installing missing packages"
        if [[ ${#missing_pacman[@]} -gt 0 ]]; then
            pacman_install "${missing_pacman[@]}" || die "Installing packages failed. Fix the error above and run the update again."
        fi
        if [[ ${#missing_aur[@]} -gt 0 ]]; then
            aur_install "${missing_aur[@]}" || die "Installing AUR packages failed. Fix the error above and run the update again."
        fi
    fi

    if [[ "$add_hook" -eq 1 ]]; then
        setup_nethogs
    fi

    run_updater

    print_summary "Update"
}

# Entry point
main() {
    preflight
    start_logging "$@"

    if [[ -z "$MODE" ]]; then
        if [[ "$ASSUME_YES" -eq 1 ]]; then
            die "--yes needs --install or --update."
        fi

        echo -e "${C_BOLD}${C_GREEN}Welcome!${C_RESET} This script will install ${C_BOLD}dots-hyprland${C_RESET} on your system."
        echo

        local choice
        while [[ -z "$MODE" ]]; do
            read -rp "$(echo -e "${C_YELLOW}[?]${C_RESET} Do you want to [i]nstall or [u]pdate? ")" choice \
                || die "No answer given."
            case "$choice" in
                [Ii]|[Ii][Nn][Ss][Tt][Aa][Ll][Ll])
                    MODE=install
                    ;;
                [Uu]|[Uu][Pp][Dd][Aa][Tt][Ee])
                    MODE=update
                    ;;
                *)
                    echo "Please enter 'i' for install or 'u' for update."
                    ;;
            esac
        done
    fi

    case "$MODE" in
        install)
            do_install
            ;;
        update)
            do_update
            ;;
        backup)
            do_backup_only
            ;;
    esac
}

main "$@"
