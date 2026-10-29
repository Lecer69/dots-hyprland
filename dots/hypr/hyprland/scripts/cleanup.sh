#!/usr/bin/env bash
# Disk cleanup for the lis shell's settings (Cleanup page).
#
#   cleanup.sh scan  <keep> [item...]   prints {"item": {"bytes": N, "count": N}, ...}
#   cleanup.sh clean <keep> [item...]   deletes them. Exits 126/127 if the
#                                       password prompt is dismissed (nothing
#                                       is deleted then), 1 if some files
#                                       couldn't be deleted, 3 if a cache was
#                                       skipped because pacman or yay was
#                                       using it
#
# <keep> is how many cached versions of each package pacman keeps.
# Items: pacman coredumps (root, through cleanup-root.sh) and yay trash
# thumbnails crashes (this user). No items means all of them.
#
# Every path is checked to be inside its item's folder before it's deleted,
# and path lists are NUL-separated, so no file name can send the deletion
# anywhere else.

set -u

# All paths below are absolute; this keeps a stray relative one out of the
# home folder (the shell's working directory)
cd / || exit 1

mode=${1:-}
keep=${2:-}
shift 2 2>/dev/null
items=("$@")
[ ${#items[@]} -eq 0 ] && items=(pacman coredumps yay trash thumbnails crashes)

if [[ $mode != scan && $mode != clean ]] || ! [[ $keep =~ ^[0-9]$ ]]; then
    echo "usage: cleanup.sh scan|clean <keep 0-9> [item...]" >&2
    exit 2
fi

here=$(dirname "$(realpath "$0")")
cache=$(realpath -m -- "${XDG_CACHE_HOME:-$HOME/.cache}")
trash=$(realpath -m -- "${XDG_DATA_HOME:-$HOME/.local/share}/Trash")
coredumps=/var/lib/systemd/coredump

# yay's build folder. Folders in it that aren't an installed package's clone
# are deleted whole, so it's only used when it's inside the cache folder
yaydir=$(yay -Pg 2>/dev/null | jq -r '.buildDir // empty' 2>/dev/null)
[ -n "$yaydir" ] || yaydir=$cache/yay
yaydir=$(realpath -m -- "$yaydir")
[[ $yaydir == "$cache"/?* ]] || yaydir=""

# Bytes under a path. Only digits get through: du prints the name after the
# size, a name can hold newlines, and $(( )) would evaluate whatever text
# followed (including $(...) in an array subscript)
size() {
    local s
    s=$(du -sb -- "$1" 2>/dev/null | head -n1 | cut -f1)
    [[ $s =~ ^[0-9]+$ ]] || s=0
    echo "$s"
}

# Whether path $2 is strictly inside folder $1, with no .. stepping out
inside() {
    local root=$1 path=$2
    [[ -n $root && $path == "$root"/?* && $path != *"/../"* && $path != *"/.." && $path != *"/./"* ]]
}

# The folder an item's deletions must stay inside
item_root() {
    case $1 in
        trash) echo "$trash" ;;
        thumbnails) echo "$cache/thumbnails" ;;
        crashes) echo "$cache/quickshell/crashes" ;;
        coredumps) echo "$coredumps" ;;
        yay) echo "$yaydir" ;;
    esac
}

# Absolute paths an item deletes, NUL-separated. find doesn't follow
# symlinks, so a folder that's a symlink lists nothing.
targets() {
    local dir
    case $1 in
        trash)
            for dir in "$trash/files" "$trash/info" "$trash/expunged"; do
                [ -d "$dir" ] && find "$dir" -mindepth 1 -maxdepth 1 -print0
            done
            # Trash's size cache, rebuilt by file managers
            [ -f "$trash/directorysizes" ] && printf '%s\0' "$trash/directorysizes"
            ;;
        thumbnails|crashes)
            dir=$(item_root "$1")
            [ -d "$dir" ] && find "$dir" -mindepth 1 -maxdepth 1 -print0
            ;;
        coredumps)
            find "$coredumps" -mindepth 1 -maxdepth 1 -name 'core.*' -print0 2>/dev/null
            ;;
        yay)
            yay_targets
            ;;
    esac
    return 0
}

# targets, minus anything outside the item's folder
checked_targets() {
    local root t
    root=$(item_root "$1")
    while IFS= read -r -d '' t; do
        if inside "$root" "$t"; then
            printf '%s\0' "$t"
        else
            echo "cleanup: refusing $t, it's outside $root" >&2
        fi
    done < <(targets "$1")
}

# yay keeps a git clone per AUR package. Clones of packages that aren't
# installed go whole. The rest keep their clone (yay diffs PKGBUILDs against
# it) and lose only the files git doesn't track: downloaded sources, src/,
# pkg/ and built packages. Clones with local PKGBUILD edits are treated
# like installed ones, so the edits stay. Only real clones count: a folder
# (not a symlink) with a PKGBUILD and .git.
declare -A installed=()

yay_is_installed() {
    local d=$1 names n
    mapfile -t names < <(sed -n 's/^pkgname = //p' "$d/.SRCINFO" 2>/dev/null)
    [ ${#names[@]} -gt 0 ] || names=("$(basename "$d")")
    for n in "${names[@]}"; do
        [ -n "${installed[$n]:-}" ] && return 0
    done
    return 1
}

yay_targets() {
    local d f p pkgs edits
    [ -n "$yaydir" ] && [ -d "$yaydir" ] || return
    # Without the package list every clone would look uninstalled
    if ! pkgs=$(pacman -Qq) || [ -z "$pkgs" ]; then
        echo "cleanup: couldn't list installed packages, skipping the AUR cache" >&2
        return
    fi
    while IFS= read -r p; do installed[$p]=1; done <<< "$pkgs"

    for d in "$yaydir"/*/; do
        d=${d%/}
        [ -L "$d" ] && continue
        [ -f "$d/PKGBUILD" ] && [ -d "$d/.git" ] || continue
        # A clone git can't read is left alone
        edits=$(git -C "$d" status --porcelain --untracked-files=no 2>/dev/null) || continue
        if [ -z "$edits" ] && ! yay_is_installed "$d"; then
            printf '%s\0' "$d"
        else
            # git quotes names with control characters, so one per line
            git -C "$d" clean -ndx 2>/dev/null | sed -n 's/^Would remove //p' | while IFS= read -r f; do
                printf '%s\0' "$d/${f%/}"
            done
        fi
    done
}

# Cached package files paccache would remove: versions past <keep> of every
# package, all versions of uninstalled ones, and their signatures and
# partial downloads
scan_pacman() {
    local bytes=0 count=0 name dir dirs
    mapfile -t dirs < <(pacman-conf CacheDir 2>/dev/null)
    [ ${#dirs[@]} -eq 0 ] && dirs=(/var/cache/pacman/pkg)
    while IFS= read -r name; do
        for dir in "${dirs[@]}"; do
            if [ -f "$dir/$name" ]; then
                bytes=$((bytes + $(size "$dir/$name")))
                [[ $name == *.sig ]] || count=$((count + 1))
                break
            fi
        done
    done < <({ paccache -dvk "$keep" 2>/dev/null; paccache -dvuk0 2>/dev/null; } \
        | grep -E '\.pkg\.tar\.[a-z0-9]+(\.sig|\.part)?$' | sort -u)
    echo "$bytes $count"
}

scan_item() {
    local bytes=0 count=0 t
    while IFS= read -r -d '' t; do
        bytes=$((bytes + $(size "$t")))
        count=$((count + 1))
    done < <(checked_targets "$1")
    echo "$bytes $count"
}

# rm -rf can't empty folders without write permission (makepkg leaves some
# behind), so open those up first. Neither find nor rm follows symlinks, so
# nothing outside the targets is touched.
remove() {
    find "$@" -type d ! -perm -u=rwx -exec chmod u+rwx {} + 2>/dev/null
    rm -rf -- "$@"
}

# A running pacman holds this lock, and its partial downloads are in the cache
pacman_busy() {
    [ -e /var/lib/pacman/db.lck ]
}

# Builds run inside yay's clones
yay_busy() {
    pgrep -x 'yay|paru|makepkg' >/dev/null
}

if [ "$mode" = scan ]; then
    out=()
    for item in "${items[@]}"; do
        case $item in
            pacman) read -r bytes count < <(scan_pacman) ;;
            coredumps|yay|trash|thumbnails|crashes) read -r bytes count < <(scan_item "$item") ;;
            *) continue ;;
        esac
        out+=("\"$item\": {\"bytes\": $bytes, \"count\": $count}")
    done
    (IFS=,; echo "{${out[*]}}")
    exit 0
fi

failed=0
skipped=0

# clean: system items first, so the password prompt comes right away and
# dismissing it stops before anything is deleted
root_items=()
for item in "${items[@]}"; do
    case $item in
        pacman)
            if pacman_busy; then
                echo "cleanup: pacman is running, skipped its cache" >&2
                skipped=1
            else
                root_items+=(pacman)
            fi
            ;;
        coredumps)
            root_items+=(coredumps)
            ;;
    esac
done
if [ ${#root_items[@]} -gt 0 ]; then
    pkexec "$here/cleanup-root.sh" "$keep" "${root_items[@]}"
    status=$?
    case $status in
        0) ;;
        126|127) exit "$status" ;;
        3) skipped=1 ;;
        *) failed=1 ;;
    esac
fi

for item in "${items[@]}"; do
    case $item in
        yay|trash|thumbnails|crashes)
            if [ "$item" = yay ] && yay_busy; then
                echo "cleanup: yay or makepkg is running, skipped the AUR cache" >&2
                skipped=1
                continue
            fi
            mapfile -d '' -t paths < <(checked_targets "$item")
            if [ ${#paths[@]} -gt 0 ] && ! remove "${paths[@]}"; then
                echo "cleanup: some $item files couldn't be deleted" >&2
                failed=1
            fi
            ;;
    esac
done

[ $failed -eq 1 ] && exit 1
[ $skipped -eq 1 ] && exit 3
exit 0
