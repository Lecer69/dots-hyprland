#!/usr/bin/env bash
# Screenshot of a region: copied, and saved to ~/Pictures/Screenshots.
# grim captures every screen first, the lis shell shows that capture over
# them while slurp picks the region (screenshot/ScreenFreeze.qml; hyprpicker's
# freeze, which hyprshot uses, draws rotated monitors sideways), and the
# region is cut from that same capture.
set -uo pipefail

# One at a time
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/screenshot-region.running"
flock -n 9 || exit 0

tmp_dir="$(mktemp -d)"
capture="$tmp_dir/screens.ppm"
shot="$tmp_dir/region.png"
frozen=0

unfreeze() {
    [ "$frozen" -eq 1 ] || return 0
    frozen=0
    qs -c lis ipc call screenshot unfreeze >/dev/null 2>&1
}
trap 'unfreeze; rm -rf "$tmp_dir"' EXIT
trap 'exit 1' INT TERM HUP

# Uncompressed, so it's quick to write and for the shell to read
grim -t ppm "$capture" || exit 1

# The capture covers the area of every screen, at the highest scale of them
read -r left top scale screens < <(hyprctl monitors -j | jq -r '"\(map(.x) | min) \(map(.y) | min) \(map(.scale) | max) \(length)"')

frozen=1
qs -c lis ipc call screenshot freeze "$capture" "$$" >/dev/null 2>&1
# slurp has to come up over the freeze, so wait for it on every screen. Without
# the shell this gives up after a second, and the region is picked unfrozen
for _ in $(seq 40); do
    shown="$(hyprctl layers -j | jq '[.. | .namespace? // empty | select(. == "quickshell:freeze")] | length')"
    [ "$shown" -ge "$screens" ] && break
    sleep 0.025
done

geometry="$(slurp -d -f '%x %y %w %h')" || exit 0
unfreeze

read -r x y w h <<<"$geometry"
crop="$(awk -v x="$x" -v y="$y" -v w="$w" -v h="$h" -v left="$left" -v top="$top" -v s="$scale" \
    'BEGIN { printf "%dx%d+%d+%d", w * s + 0.5, h * s + 0.5, (x - left) * s + 0.5, (y - top) * s + 0.5 }')"
magick "$capture" -crop "$crop" +repage "$shot" || exit 1

# It stays to serve the clipboard, so it mustn't hold the lock
wl-copy --type image/png < "$shot" 9>&-

dest_dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dest_dir"
cp "$shot" "$dest_dir/screenshot_$(date "+%Y-%m-%d_%H.%M.%S").png"
