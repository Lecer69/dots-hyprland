#!/bin/bash

set -e

USER_NAME="$USER"

echo "This will enable Hyprland auto-login setup for: $USER_NAME"
echo "It will modify:"
echo " - ~/.bash_profile"
echo " - /etc/systemd/system/getty@tty1.service.d/override.conf"
echo

read -p "Are you sure you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Aborted."
    exit 0
fi

touch "$HOME/.bash_profile"
cp "$HOME/.bash_profile" "$HOME/.bash_profile.bak"

grep -q "Hyprland auto-start" "$HOME/.bash_profile" || cat >> "$HOME/.bash_profile" <<'EOF'

# Hyprland auto-start (tty1 only)
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$(tty)" = "/dev/tty1" ]; then
    exec > /dev/null 2>&1
    exec dbus-run-session start-hyprland
fi
EOF

sudo mkdir -p /etc/systemd/system/getty@tty1.service.d

sudo tee /etc/systemd/system/getty@tty1.service.d/override.conf > /dev/null <<EOF
[Service]
ExecStart=
ExecStart=-/usr/bin/agetty --autologin $USER_NAME --noclear %I \$TERM
EOF

sudo systemctl daemon-reload
echo "Done. Reboot to apply changes."