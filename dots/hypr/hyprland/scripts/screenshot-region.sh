#!/usr/bin/env bash
set -uo pipefail

out_dir="/tmp"
tmp_before="$(mktemp -u "${out_dir}/hyprshot_marker.XXXXXX")"
touch "$tmp_before"

hyprshot --freeze --mode region --silent --output-folder "$out_dir"
hyprshot_status=$?

rm -f "$tmp_before"

if [ "$hyprshot_status" -ne 0 ]; then
    echo "hyprshot failed or was cancelled (exit $hyprshot_status)" >&2
    exit "$hyprshot_status"
fi

latest="$(find "$out_dir" -maxdepth 1 -name '*.png' -newer "$tmp_before" -print 2>/dev/null | head -1)"
if [ -z "$latest" ]; then
    latest="$(ls -t "$out_dir"/*.png 2>/dev/null | head -1)"
fi

if [ -z "$latest" ] || [ ! -f "$latest" ]; then
    echo "No screenshot found" >&2
    exit 1
fi

prev_size=-1
for _ in $(seq 1 20); do
    cur_size=$(stat -c%s "$latest" 2>/dev/null || echo -1)
    if [ "$cur_size" -eq "$prev_size" ] && [ "$cur_size" -gt 0 ]; then
        break
    fi
    prev_size=$cur_size
    sleep 0.05
done

if command -v identify >/dev/null 2>&1; then
    if ! identify "$latest" >/dev/null 2>&1; then
        echo "Warning: screenshot file looks incomplete/corrupt: $latest" >&2
    fi
fi

wl-copy < "$latest"

dest_dir="$(xdg-user-dir PICTURES)/Screenshots"
mkdir -p "$dest_dir"
cp "$latest" "$dest_dir/screenshot_$(date "+%Y-%m-%d_%H.%M.%S").png"