#!/usr/bin/env bash
for cmd in "$@"; do
    [[ -z "$cmd" ]] && continue
    if [[ "$cmd" == "command -v "* ]]; then
        # 'command -v X && Y': Y, if X is installed
        eval "${cmd%%&&*}" >/dev/null 2>&1 || continue
        cmd="${cmd#*&&}"
    else
        eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
    fi
    eval "$cmd" &
    exit
done
