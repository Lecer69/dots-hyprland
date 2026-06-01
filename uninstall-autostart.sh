#!/bin/bash

set -e

USER_NAME="$USER"

echo "This will REMOVE Hyprland auto-login setup for: $USER_NAME"
echo "It will revert:"
echo " - ~/.bash_profile Hyprland block"
echo " - getty@tty1 autologin override"
echo

read -p "Are you sure you want to uninstall? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

if [ -f "$HOME/.bash_profile.bak" ]; then
    cp "$HOME/.bash_profile.bak" "$HOME/.bash_profile"
    echo "Restored .bash_profile from backup"
else
    sed -i '/Hyprland auto-start/,+5d' "$HOME/.bash_profile" 2>/dev/null || true
    echo "Removed Hyprland block from .bash_profile"
fi

sudo rm -f /etc/systemd/system/getty@tty1.service.d/override.conf

sudo rmdir /etc/systemd/system/getty@tty1.service.d 2>/dev/null || true

sudo systemctl daemon-reload
echo "Done. Reboot to fully apply changes."