#!/usr/bin/env bash
set -uo pipefail

hyprctl keyword cursor:invisible 1

hyprshot --freeze --mode region --silent --output-folder /tmp

hyprctl keyword cursor:invisible 0

latest="$(ls -t /tmp/*.png | head -1)"
wl-copy < "$latest"

dest_dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dest_dir"
cp "$latest" "$dest_dir/screenshot_$(date "+%Y-%m-%d_%H.%M.%S").png"
