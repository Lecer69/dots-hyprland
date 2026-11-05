#!/bin/sh
# Figures for settings/pages/SystemPage.qml, one "key value" per line

user=$(id -un)
echo "user $user"
echo "name $(getent passwd "$user" | cut -d: -f5 | cut -d, -f1)"
echo "host $(cat /proc/sys/kernel/hostname)"
echo "shell ${SHELL##*/}"

. /etc/os-release 2>/dev/null
echo "os ${PRETTY_NAME:-Linux}"

echo "kernel $(uname -r)"
echo "build $(uname -v | sed 's/^#[0-9]* *//')"
echo "arch $(uname -m)"

read -r up _ < /proc/uptime
echo "uptime $up"

command -v pacman >/dev/null && echo "packages $(pacman -Qq | wc -l)"

echo "hyprland $(hyprctl version 2>/dev/null | awk 'NR == 1 { print $2 }')"
echo "quickshell $(qs --version 2>/dev/null | awk 'NR == 1 { print $2 }')"

echo "cpu $(awk -F ': ' '/^model name/ { print $2; exit }' /proc/cpuinfo)"
echo "cores $(nproc)"
echo "memory $(awk '/^MemTotal/ { print $2; exit }' /proc/meminfo)"

lspci -mm 2>/dev/null | awk -F '"' '$2 ~ /VGA|3D|Display/ { print "gpu", $6 }'
