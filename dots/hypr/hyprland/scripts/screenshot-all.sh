#!/usr/bin/env bash
set -uo pipefail

tmp_file="/tmp/screenshot_tmp.png"

grim "$tmp_file"
wl-copy < "$tmp_file"

dest_dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dest_dir"
cp "$tmp_file" "$dest_dir/screenshot_$(date "+%Y-%m-%d_%H.%M.%S").png"
