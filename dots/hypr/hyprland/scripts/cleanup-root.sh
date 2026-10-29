#!/usr/bin/env bash
# The system half of cleanup.sh, run as root through pkexec:
#
#   cleanup-root.sh <keep> [pacman] [coredumps]
#
# pacman: keeps the last <keep> versions of each package in the pacman cache
# and drops every version of uninstalled ones. coredumps: deletes systemd's
# saved crash dumps. Nothing else is accepted. Exits 1 if something failed,
# 3 if the pacman cache was skipped because pacman is running.

set -u
cd / || exit 1

keep=${1:-}
if ! [[ $keep =~ ^[0-9]$ ]]; then
    echo "usage: cleanup-root.sh <keep 0-9> [pacman] [coredumps]" >&2
    exit 2
fi
shift

failed=0
skipped=0
for item in "$@"; do
    case $item in
        pacman)
            # A running pacman's partial downloads are in the cache. Checked
            # again here, as the password prompt can take a while.
            if [ -e /var/lib/pacman/db.lck ]; then
                echo "cleanup-root.sh: pacman is running, skipped its cache" >&2
                skipped=1
                continue
            fi
            paccache -rqk "$keep" || failed=1
            paccache -rquk0 || failed=1
            ;;
        coredumps)
            find /var/lib/systemd/coredump -mindepth 1 -maxdepth 1 -name 'core.*' -delete || failed=1
            ;;
        *)
            echo "cleanup-root.sh: unknown item $item" >&2
            exit 2
            ;;
    esac
done

[ $failed -eq 1 ] && exit 1
[ $skipped -eq 1 ] && exit 3
exit 0
