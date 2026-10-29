#!/bin/sh
# Figures for tools/SystemStats.qml, one per line:
#   uptime SECONDS
#   net INTERFACE RX_BYTES TX_BYTES       (the default route's interface)
#   disk SIZE USED MOUNT                  (bytes)
#   cputemp MILLIDEGREES
#   gpu USAGE% MEM_USED MEM_TOTAL TEMP NAME   (MiB, °C; "-" when unknown)
#   gpu off NAME                          (powered down, so not read)

read -r up _ < /proc/uptime
echo "uptime $up"

iface=$(awk '$2 == "00000000" { print $1; exit }' /proc/net/route)
if [ -n "$iface" ]; then
    awk -F '[: ]+' -v i="$iface" '$2 == i { print "net", i, $3, $11 }' /proc/net/dev
fi

df -B1 --output=target,size,used / /home 2>/dev/null |
    awk 'NR > 1 && !seen[$1]++ { print "disk", $2, $3, $1 }'

for h in /sys/class/hwmon/hwmon*; do
    case $(cat "$h/name" 2>/dev/null) in
    k10temp | zenpower | coretemp | cpu_thermal)
        echo "cputemp $(cat "$h/temp1_input")"
        break
        ;;
    esac
done

gpu_name() {
    lspci -mm -s "$1" 2>/dev/null | awk -F '"' '{ print $6 }'
}

# Reads a sysfs number, divided by $2; "-" when it can't be read
read_div() {
    v=$(cat "$1" 2>/dev/null | head -n 1)
    if [ -n "$v" ]; then echo $((v / $2)); else echo -; fi
}

for card in /sys/class/drm/card*; do
    # Skip connectors (card1-DP-1)
    case ${card##*/} in *-*) continue ;; esac
    dev=$card/device
    slot=$(basename "$(readlink -f "$dev")")

    # Reading a GPU that's powered down (a laptop's dGPU) would wake it up
    if [ "$(cat "$dev/power/runtime_status" 2>/dev/null)" = suspended ]; then
        echo "gpu off $(gpu_name "$slot")"
        continue
    fi

    case $(cat "$dev/vendor") in
    0x10de)
        nvidia-smi --id="$slot" --format=csv,noheader,nounits \
            --query-gpu=utilization.gpu,memory.used,memory.total,temperature.gpu,name 2>/dev/null |
            awk -F ', ' '{ print "gpu", $1, $2, $3, $4, $5 }'
        ;;
    *)
        # amdgpu; other drivers (Intel) have no usage counter
        [ -r "$dev/gpu_busy_percent" ] || continue
        set -- "$dev"/hwmon/hwmon*/temp1_input
        echo "gpu $(cat "$dev/gpu_busy_percent")" \
            "$(read_div "$dev/mem_info_vram_used" 1048576)" \
            "$(read_div "$dev/mem_info_vram_total" 1048576)" \
            "$(read_div "$1" 1000)" \
            "$(gpu_name "$slot")"
        ;;
    esac
done
