pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Pre-blurs lock screen wallpapers into a disk cache so locking is instant.
// Cache key = wallpaper path + file mtime/size + blur params; when the
// background file is updated, the key changes and it gets re-blurred/recached.
QtObject {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/lis/lockblur"
    property var _ready: ({})   // key -> blurred file path
    property var _pending: ({}) // key -> true while a job runs

    signal ready(string key, string path)

    readonly property string _script: `
wp="$1"; bsize="$2"; bpasses="$3"
dir="$HOME/.cache/lis/lockblur"
mkdir -p "$dir" 2>/dev/null
[ -f "$wp" ] || { echo "ERR missing-wallpaper"; exit 0; }
# prune stale entries (never touched for 30 days)
find "$dir" -maxdepth 1 -name "*.jpg" -mtime +30 -delete 2>/dev/null
mt=$(stat -c '%Y:%s' "$wp" 2>/dev/null); [ -n "$mt" ] || mt="x"
key=$(printf '%s|v3|%s|%s|%s' "$wp" "$mt" "$bsize" "$bpasses" | sha1sum | cut -d" " -f1)
out="$dir/$key.jpg"
if [ -s "$out" ]; then echo "READY $out"; exit 0; fi
sig=$(awk -v r="$bsize" -v p="$bpasses" 'BEGIN{
    sig=(r/2.0)*sqrt(p); if (sig<0.3) sig=0.3; printf "%.2f", sig }')
tmp="$out.$$"
magick "$wp" -auto-orient -blur "0x$sig" -strip -quality 98 "$tmp" 2>/dev/null \
    || { rm -f "$tmp"; echo "ERR magick"; exit 0; }
mv "$tmp" "$out"
echo "READY $out"
`

    function keyFor(wallpaperPath, blurSize, blurPasses) {
        return wallpaperPath + "|" + blurSize + "|" + blurPasses
    }

    function cachedPath(wallpaperPath, blurSize, blurPasses) {
        return root._ready[root.keyFor(wallpaperPath, blurSize, blurPasses)] ?? ""
    }

    function ensureCached(wallpaperPath, blurSize, blurPasses) {
        if (!wallpaperPath || wallpaperPath.length === 0) return
        const key = root.keyFor(wallpaperPath, blurSize, blurPasses)
        if (root._pending[key]) return
        root._pending[key] = true

        const job = _jobComponent.createObject(root, {
            wp: wallpaperPath,
            bsize: blurSize,
            bpasses: blurPasses
        })
        if (!job) {
            delete root._pending[key]
            return
        }

        job.finished.connect(path => {
            const isNew = root._ready[key] !== path
            root._ready[key] = path
            const pending = Object.assign({}, root._pending)
            delete pending[key]
            root._pending = pending
            if (isNew) root.ready(key, path)
            job.destroy()
        })
        job.start()
    }

    component WallpaperBlurJob: QtObject {
        id: job

        property string wp
        property int bsize
        property int bpasses
        signal finished(string blurredPath)

        function start() { proc.running = true }

        property Process proc: Process {
            id: proc
            command: ["bash", "-c", root._script, "lis-blur", job.wp, String(job.bsize), String(job.bpasses)]
            stdout: StdioCollector { id: jobOut }
            stderr: StdioCollector { id: jobErr }

            onRunningChanged: {
                if (running) return

                let path = ""
                const lines = (jobOut.text || "").trim().split("\n")
                for (let i = lines.length - 1; i >= 0; i--) {
                    const line = lines[i].trim()
                    if (line.startsWith("READY ")) {
                        path = line.slice(6).trim()
                        break
                    }
                    if (line.startsWith("ERR "))
                        console.warn("[lock-blur]", line.slice(4).trim())
                }

                if (path.length > 0) {
                    job.finished(path)
                } else {
                    console.warn("[lock-blur] failed for", job.wp, (jobErr.text || "").trim())
                }
            }
        }
    }

    property Component _jobComponent: Component {
        WallpaperBlurJob {}
    }
}
