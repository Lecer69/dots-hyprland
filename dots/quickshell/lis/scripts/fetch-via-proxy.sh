#!/bin/sh
# Saves a url to a file through a proxy, if there is one, and keeps the newest 30 files beside it
# Args: url, destination file

url=$1
dest=$2
dir=$(dirname "$dest")

mkdir -p "$dir" || exit 1

if [ -s "$dest" ]; then
    touch "$dest"
    exit 0
fi

# The environment's first, then the usual ports of local proxy apps
for proxy in "${https_proxy:-}" "${HTTPS_PROXY:-}" "${all_proxy:-}" "${ALL_PROXY:-}" "${http_proxy:-}" "${HTTP_PROXY:-}" \
    http://127.0.0.1:10808 http://127.0.0.1:7890 http://127.0.0.1:2080 socks5h://127.0.0.1:1080; do
    [ -n "$proxy" ] || continue
    if curl -fsSL --proto =http,https --proxy "$proxy" --connect-timeout 3 --max-time 20 -o "$dest.part" --url "$url" 2>/dev/null; then
        mv "$dest.part" "$dest"
        cd "$dir" && ls -t | tail -n +31 | xargs -r rm -f --
        exit 0
    fi
done

rm -f "$dest.part"
exit 1
