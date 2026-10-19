pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

// Pre-blurs lock screen wallpapers into a disk cache so locking is instant.
// Files are named md5(wallpaper path + blur params), so an image blurred in
// a previous session is found synchronously at startup without spawning
// anything. A .stamp sidecar records the source's mtime:size; a background
// job re-blurs when it no longer matches (wallpaper file replaced in place).
QtObject {
    id: root

    readonly property string cacheDir: Quickshell.env("HOME") + "/.cache/lis/lockblur"

    // name -> image url; carries ?v=<stamp> so a re-blur busts Qt's pixmap cache
    property var urls: ({})
    property var _pending: ({}) // name -> true while a job runs

    readonly property string _script: `
wp="$1"; name="$2"; bsize="$3"; bpasses="$4"
dir="$HOME/.cache/lis/lockblur"
out="$dir/$name.jpg"; st="$dir/$name.stamp"
src=$(stat -c '%Y:%s' "$wp" 2>/dev/null) || { echo "ERR missing-wallpaper"; exit 0; }
old=$(cat "$st" 2>/dev/null)
# stamp = <src mtime>:<src size>:<generation time>
if [ -s "$out" ] && [ "\${old%:*}" = "$src" ]; then
    touch -c "$out" "$st"
    echo "READY $old"; exit 0
fi
mkdir -p "$dir"
# Stored downscaled by f with sigma/f: looks identical once the GPU scales
# it back up (the blur removed the detail anyway), but is ~f^3 cheaper to
# blur and ~f^2 cheaper to decode on every lock
read -r pct sig <<< "$(awk -v r="$bsize" -v p="$bpasses" 'BEGIN{
    sig=(r/2.0)*sqrt(p); if (sig<0.3) sig=0.3
    f=int(sig/3); if (f<1) f=1; if (f>4) f=4
    printf "%d %.2f", 100/f, sig/f }')"
# magick = ImageMagick 7, convert = ImageMagick 6 (Debian/Ubuntu/Fedora)
if command -v magick >/dev/null 2>&1; then
    blurcmd="magick"
else
    blurcmd="convert"
fi
tmp="$out.$$"
"$blurcmd" "$wp" -auto-orient -resize "$pct%" -blur "0x$sig" -strip -quality 92 "jpg:$tmp" 2>/dev/null \
    || { rm -f "$tmp"; echo "ERR magick"; exit 0; }
mv -f "$tmp" "$out"
new="$src:\${EPOCHREALTIME/[.,]/}"
printf '%s' "$new" > "$st"
echo "READY $new"
`

    function nameFor(wallpaperPath, blurSize, blurPasses) {
        return Qt.md5(wallpaperPath + "|v4|" + blurSize + "|" + blurPasses)
    }

    function _setUrl(name, stamp) {
        const url = "file://" + root.cacheDir + "/" + name + ".jpg?v=" + stamp
        if (root.urls[name] === url) return
        const next = Object.assign({}, root.urls)
        next[name] = url
        root.urls = next
    }

    // Synchronously picks up an image blurred in a previous session (a tiny
    // stamp file read), so the very first lock after boot shows it at once
    function prime(wallpaperPath, blurSize, blurPasses) {
        if (!wallpaperPath || wallpaperPath.length === 0) return
        const name = root.nameFor(wallpaperPath, blurSize, blurPasses)
        if (root.urls[name] !== undefined) return
        _stampReader.path = root.cacheDir + "/" + name + ".stamp"
        const stamp = _stampReader.text().trim()
        if (stamp.length > 0) root._setUrl(name, stamp)
    }

    // Validates the cached image against the wallpaper file in the
    // background, re-blurring if it changed; `urls` updates when done
    function ensureCached(wallpaperPath, blurSize, blurPasses) {
        if (!wallpaperPath || wallpaperPath.length === 0) return
        const name = root.nameFor(wallpaperPath, blurSize, blurPasses)
        if (root._pending[name]) return
        root._pending[name] = true

        const job = _jobComponent.createObject(root, {
            wp: wallpaperPath,
            name: name,
            bsize: blurSize,
            bpasses: blurPasses
        })
        if (!job) {
            delete root._pending[name]
            return
        }

        job.finished.connect(stamp => {
            delete root._pending[name]
            if (stamp.length > 0) root._setUrl(name, stamp)
            job.destroy()
        })
        job.start()
    }

    property FileView _stampReader: FileView {
        blockAllReads: true
        printErrors: false
    }

    // Drop entries not used for 30 days (validation touches live ones) and
    // the pre-v4 cache (sha1-named, full resolution). Delayed so startup
    // validation has touched everything still in use first.
    property Timer _pruneTimer: Timer {
        interval: 60000
        running: true
        onTriggered: Quickshell.execDetached(["sh", "-c",
            "d=\"$HOME/.cache/lis/lockblur\"; [ -d \"$d\" ] || exit 0; " +
            "find \"$d\" -maxdepth 1 -type f -regextype posix-extended " +
            "\\( -mtime +30 -o -regex '.*/[0-9a-f]{40}\\.jpg' \\) -delete"])
    }

    component WallpaperBlurJob: QtObject {
        id: job

        property string wp
        property string name
        property int bsize
        property int bpasses
        signal finished(string stamp)

        function start() { proc.running = true }

        property Process proc: Process {
            id: proc
            command: ["bash", "-c", root._script, "lis-blur", job.wp, job.name, String(job.bsize), String(job.bpasses)]
            stdout: StdioCollector { id: jobOut }
            stderr: StdioCollector { id: jobErr }

            onRunningChanged: {
                if (running) return

                let stamp = ""
                const lines = (jobOut.text || "").trim().split("\n")
                for (let i = lines.length - 1; i >= 0; i--) {
                    const line = lines[i].trim()
                    if (line.startsWith("READY ")) {
                        stamp = line.slice(6).trim()
                        break
                    }
                    if (line.startsWith("ERR "))
                        console.warn("[lock-blur]", line.slice(4).trim())
                }

                if (stamp.length === 0)
                    console.warn("[lock-blur] failed for", job.wp, (jobErr.text || "").trim())
                job.finished(stamp)
            }
        }
    }

    property Component _jobComponent: Component {
        WallpaperBlurJob {}
    }
}
