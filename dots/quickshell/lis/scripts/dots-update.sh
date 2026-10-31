#!/usr/bin/env bash
# Installs an update for the Dots Updater page: dots-update.sh <clone> <commit> <backup 0|1> <shell 0|1>
# Prints "step/done/fail <name>" per step; `finish`, run detached, swaps in the new shell config.
# install.sh --update runs it too: with - as the commit, for its own files as they are, and with
# DOTS_UPDATE_WAIT=1, so finish runs before this exits and a failed swap fails the shell step.

set -uo pipefail

CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}"
BACKUP_DIR="$HOME/.dots-hyprland-backups"
# Older backups are deleted
BACKUP_KEEP=10
LOG="${XDG_CACHE_HOME:-$HOME/.cache}/lis/dots-update.log"
# Until finish swaps it in
STAGED="$CONFIG_DIR/.quickshell-update"
OLD="$CONFIG_DIR/.quickshell-old"
# The commit last installed in full, a hint for dots-check.py
RECORD="${XDG_STATE_HOME:-$HOME/.local/state}/lis/dots-commit"

# Never overwritten by an update
HYPR_PRESERVE_ITEMS=(custom hyprpaper.conf monitors.conf monitors.lua workspaces.conf)

hypr_is_preserved_item() {
    local preserved
    for preserved in "${HYPR_PRESERVE_ITEMS[@]}"; do
        [[ "$1" == "$preserved" ]] && return 0
    done
    return 1
}

# dots-update.sh finish <commit> <short commit> <subject> [missing packages]; exits 1 if the swap failed
if [[ "${1:-}" == finish ]]; then
    killall -q qs quickshell
    for _ in $(seq 1 50); do
        pgrep -x 'qs|quickshell' >/dev/null || break
        sleep 0.1
    done

    # Renames, so a failure leaves the old config
    rm -rf "$OLD"
    if { [[ ! -e "$CONFIG_DIR/quickshell" && ! -L "$CONFIG_DIR/quickshell" ]] || mv "$CONFIG_DIR/quickshell" "$OLD"; } \
        && mv "$STAGED" "$CONFIG_DIR/quickshell"; then
        rm -rf "$OLD"
        if [[ -n "$2" ]]; then
            mkdir -p "${RECORD%/*}" && echo "$2" >"$RECORD"
        else
            rm -f "$RECORD"
        fi
        message="Now on $3${4:+ · $4}"
        status=0
    else
        [[ -e "$CONFIG_DIR/quickshell" || ! -e "$OLD" ]] || mv "$OLD" "$CONFIG_DIR/quickshell"
        message="Couldn't replace ~/.config/quickshell, see ${LOG/#$HOME/\~}"
        status=1
    fi
    [[ -n "${5:-}" ]] && message+=$'\n'"Missing packages: $5"

    hyprctl reload
    # Set on the shell Hyprland started; it would lock the screen
    env -u ON_HYPRSTART setsid -f qs -c lis >/dev/null 2>&1 </dev/null

    # Once the new shell takes notifications
    sleep 3
    timeout 10 notify-send -a "Dots Updater" "Dots updated" "$message"
    exit "$status"
fi

clone="$1"
commit="$2"
backup="$3"
shell="$4"
dots="$clone/dots"

step() {
    current="$1"
    echo "step $1"
}

step_done() {
    echo "done $current${1:+ $1}"
}

fail() {
    echo "fail $current $*"
    exit 1
}

# Deletes all but the newest $BACKUP_KEEP backups. Only touches files named like
# the ones made here and by install.sh, which sort oldest first
prune_backups() {
    local LC_ALL=C
    local -a backups
    shopt -s nullglob
    backups=("$BACKUP_DIR"/[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]_[0-9][0-9]-[0-9][0-9]-[0-9][0-9].zip)
    shopt -u nullglob
    local excess=$(( ${#backups[@]} - BACKUP_KEEP ))
    (( excess > 0 )) && rm -f -- "${backups[@]:0:excess}"
    return 0
}

step checkout
if [[ "$shell" == 1 ]]; then
    for path in "$CONFIG_DIR/quickshell" "$CONFIG_DIR"/quickshell/*; do
        [[ -e "$path/.git" ]] && fail "${path/#$HOME/\~} is a git checkout, which the update would delete"
    done
fi
if [[ "$commit" == - ]]; then
    # install.sh's own files, as they are
    rev=HEAD
    [[ -d "$dots" ]] || fail "No dots folder in ${clone/#$HOME/\~}"
    sha="$(git -C "$clone" rev-parse HEAD 2>/dev/null)" || sha=""
    short="${sha:0:7}"
    [[ -n "$short" ]] || short="local files"
else
    rev="$commit"
    [[ -d "$clone/.git" ]] || fail "No clone at ${clone/#$HOME/\~}, check for updates first"
    git -C "$clone" reset --quiet --hard "$commit" || fail "Couldn't check out ${commit:0:7}"
    [[ -d "$dots" ]] || fail "${commit:0:7} has no dots folder"
    sha="$(git -C "$clone" rev-parse HEAD)"
    short="${sha:0:7}"
fi
step_done "$short"

# What this commit's package lists have that isn't installed. install.sh offers
# to install it; the Dots Updater page shows it
step packages
packages=()
for list in "$clone/packages/pacman.txt" "$clone/packages/aur.txt"; do
    [[ -f "$list" ]] || continue
    while IFS= read -r line || [[ -n "$line" ]]; do
        read -ra words <<<"${line%%#*}"
        packages+=("${words[@]}")
    done <"$list"
done
missing=""
if [[ ${#packages[@]} -gt 0 ]] && command -v pacman >/dev/null 2>&1; then
    # pacman -T prints the names no installed package provides
    missing="$(pacman -T "${packages[@]}" | tr '\n' ' ')"
    missing="${missing% }"
fi
step_done "$missing"

if [[ "$backup" == 1 ]]; then
    step backup
    command -v zip >/dev/null 2>&1 || fail "zip isn't installed"

    candidates=(hypr)
    [[ "$shell" == 1 ]] && candidates+=(quickshell)
    to_backup=()
    for name in "${candidates[@]}"; do
        [[ -e "$CONFIG_DIR/$name" ]] && to_backup+=("$name")
    done

    if [[ ${#to_backup[@]} -eq 0 ]]; then
        step_done "Nothing to back up"
    else
        mkdir -p "$BACKUP_DIR" || fail "Couldn't create ${BACKUP_DIR/#$HOME/\~}"
        zip_path="$BACKUP_DIR/$(date +%Y-%m-%d_%H-%M-%S).zip"
        if ! (cd "$CONFIG_DIR" && zip -r -q "$zip_path" "${to_backup[@]}"); then
            rm -f "$zip_path"
            fail "Couldn't create ${zip_path/#$HOME/\~}"
        fi
        prune_backups
        step_done "${zip_path/#$HOME/\~}"
    fi
fi

step hypr
if [[ -d "$dots/hypr" ]]; then
    mkdir -p "$CONFIG_DIR/hypr" || fail "Couldn't create ~/.config/hypr"

    shopt -s dotglob nullglob
    for item in "$dots/hypr"/*; do
        name="$(basename "$item")"
        hypr_is_preserved_item "$name" && continue

        target="$CONFIG_DIR/hypr/$name"
        if [[ -e "$target" || -L "$target" ]]; then
            rm -rf "$target" || fail "Couldn't remove ~/.config/hypr/$name"
        fi
        cp -r "$item" "$target" || fail "Couldn't copy hypr/$name"
    done
    shopt -u dotglob nullglob

    step_done
else
    step_done "Not in this commit"
fi

step command
if [[ -e "$clone/extra/lis" ]]; then
    dest="$HOME/.local/bin/lis"
    mkdir -p "$HOME/.local/bin" && rm -rf "$dest" && cp -r "$clone/extra/lis" "$dest" \
        || fail "Couldn't install ~/.local/bin/lis"
    chmod +x "$dest" 2>/dev/null
    step_done
else
    step_done "Not in this commit"
fi

if [[ "$shell" == 1 ]]; then
    step shell
    [[ -d "$dots/quickshell" ]] || fail "$short has no quickshell config"
    rm -rf "$STAGED" && cp -r "$dots/quickshell" "$STAGED" || fail "Couldn't copy the new shell"

    subject="$(git -C "$clone" log -1 --format=%s "$rev" 2>/dev/null)"
    mkdir -p "$(dirname "$LOG")"
    if [[ "${DOTS_UPDATE_WAIT:-0}" == 1 ]]; then
        bash "$0" finish "$sha" "$short" "$subject" "$missing" >"$LOG" 2>&1 </dev/null \
            || fail "Couldn't replace ~/.config/quickshell, see ${LOG/#$HOME/\~}"
    else
        setsid -f bash "$0" finish "$sha" "$short" "$subject" "$missing" >"$LOG" 2>&1 </dev/null
    fi
    step_done
else
    step reload
    hyprctl reload >/dev/null || fail "hyprctl reload failed"
    step_done
fi
