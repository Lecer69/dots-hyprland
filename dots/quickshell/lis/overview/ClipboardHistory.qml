pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

// cliphist history for the launcher. Kept loaded and current (cliphist's
// database is watched, and `cliphist list` takes a few ms), so the clipboard
// view opens instantly. Image entries get small thumbnails, made once per
// entry in the background and kept in a disk cache.
Singleton {
    id: root

    readonly property string _cacheHome: Quickshell.env("XDG_CACHE_HOME") || (Quickshell.env("HOME") + "/.cache")
    // cliphist's default database; only watched for changes, never read
    readonly property string dbPath: Quickshell.env("CLIPHIST_DB_PATH") || (root._cacheHome + "/cliphist/db")
    readonly property string thumbDir: root._cacheHome + "/lis/clipthumbs"

    // Newest first. `lines` are `cliphist list` lines ("<id>\t<preview>"),
    // which views use as model values as-is (unique, cheap to diff);
    // `search` has each line's lowercased search text. One object, so
    // bindings never see one updated without the other.
    property var history: ({ lines: [], search: [] })

    // id -> thumbnail url, once the thumbnail is on disk
    property var thumbs: ({})

    function idOf(line) {
        const tab = line.indexOf("\t")
        return tab < 0 ? line : line.slice(0, tab)
    }

    function textOf(line) {
        const tab = line.indexOf("\t")
        return tab < 0 ? "" : line.slice(tab + 1)
    }

    // "[[ binary data 101 KiB png 1160x477 ]]" -> { size, format, width, height }
    function imageInfo(line) {
        const m = root.textOf(line).match(/^\[\[ binary data (.+) (\w+) (\d+)x(\d+) \]\]$/)
        return m ? { size: m[1], format: m[2], width: Number(m[3]), height: Number(m[4]) } : null
    }

    function filter(query) {
        const h = root.history
        const q = query.toLowerCase()
        if (q.length === 0) return h.lines

        const out = []
        for (let i = 0; i < h.lines.length; i++) {
            if (h.search[i].includes(q)) out.push(h.lines[i])
        }
        return out
    }

    // Puts an entry back on the clipboard. wl-copy forks and keeps serving
    // it, so it outlives the launcher (and shell reloads).
    function copy(line) {
        if (typeof line !== "string") return
        const id = root.idOf(line)
        if (!/^\d+$/.test(id)) return

        const info = root.imageInfo(line)
        const type = info ? ["--type", "image/" + info.format]
            : root.textOf(line).startsWith("file://") ? ["--type", "text/uri-list"]
            : []
        Quickshell.execDetached(["sh", "-c", 'id="$1"; shift; cliphist decode "$id" | wl-copy "$@"', "sh", id].concat(type))
    }

    // The launcher calls this at startup and when the clipboard view opens;
    // the database watch below keeps the history current in between. Cheap,
    // and a no-op for views when nothing changed.
    function refresh() {
        if (listProc.running) root._relist = true
        else listProc.running = true
    }

    property bool _relist: false
    property string _listed: "\n" // last applied `cliphist list` output

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector { id: listOut }
        stderr: StdioCollector { id: listErr }

        onExited: code => {
            if (code === 0) root._apply(listOut.text)
            // No database until something is copied
            else if (listErr.text.includes("store something first")) root._apply("")
            else console.warn("[clipboard] cliphist list failed:", listErr.text.trim())

            if (root._relist) {
                root._relist = false
                Qt.callLater(root.refresh)
            }
        }
    }

    // Each copy writes the database, usually several times in a burst (and
    // once per wl-paste watcher), so changes are batched
    FileView {
        path: root.dbPath
        preload: false
        watchChanges: true
        printErrors: false
        onFileChanged: refreshDebounce.restart()
    }

    Timer {
        id: refreshDebounce
        interval: 250
        onTriggered: root.refresh()
    }

    function _apply(text) {
        if (text === root._listed) return
        root._listed = text

        const lines = []
        const search = []
        const images = []
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t")
            if (tab < 0) continue
            lines.push(line)

            const info = root.imageInfo(line)
            if (info) {
                search.push("image " + info.format + " " + info.width + "x" + info.height)
                images.push({ id: line.slice(0, tab), name: root._thumbName(line.slice(0, tab), info) })
            } else {
                search.push(line.slice(tab + 1).toLowerCase())
            }
        }

        root.history = { lines: lines, search: search }
        root._syncThumbs(images)
    }

    // The name carries the image size too, so if ids ever restart (a new
    // database), a reused id can't pick up a stale thumbnail
    function _thumbName(id, info) {
        return id + "-" + info.width + "x" + info.height + ".png"
    }

    property string _thumbSet: "\n" // image entries the cache was last synced to
    property var _thumbJob: []
    property bool _thumbRerun: false
    property var _thumbsSeen: ({}) // reported by the running job

    function _syncThumbs(images) {
        const key = images.map(e => e.name).join("/")
        if (key === root._thumbSet) return
        root._thumbSet = key
        root._thumbJob = images

        if (thumbProc.running) root._thumbRerun = true
        else root._startThumbs()
    }

    function _startThumbs() {
        const args = []
        for (const e of root._thumbJob) args.push(e.id, e.name)
        root._thumbsSeen = {}
        thumbProc.command = ["nice", "-n", "10", "bash", "-c", root._thumbScript, "lis-clipthumbs", root.thumbDir].concat(args)
        thumbProc.running = true
    }

    function _publishThumbs() {
        root.thumbs = Object.assign({}, root.thumbs, root._thumbsSeen)
    }

    function _sameThumbs(map) {
        const keys = Object.keys(map)
        if (keys.length !== Object.keys(root.thumbs).length) return false
        return keys.every(k => root.thumbs[k] === map[k])
    }

    // Args: dir, then id/name pairs (newest first). Makes missing
    // thumbnails, prints "OK <id> <name>" per thumbnail on disk, and deletes
    // the ones whose entry left the history.
    readonly property string _thumbScript: `
dir="$1"; shift
mkdir -p "$dir" || exit 1
vips=$(command -v vipsthumbnail)
im=$(command -v magick || command -v convert)
declare -A keep
while [ $# -ge 2 ]; do
    id="$1"; name="$2"; shift 2
    keep[$name]=1
    out="$dir/$name"
    if [ ! -s "$out" ]; then
        tmp="$dir/tmp-$$-$name"
        { [ -n "$vips" ] && cliphist decode "$id" | "$vips" stdin --size '192x120>' -o "$tmp" 2>/dev/null && [ -s "$tmp" ]; } ||
        { [ -n "$im" ] && cliphist decode "$id" | "$im" '-[0]' -auto-orient -thumbnail '192x120>' -strip "png:$tmp" 2>/dev/null && [ -s "$tmp" ]; } ||
        cliphist decode "$id" > "$tmp" # no thumbnailer: the view downscales the original
        if [ -s "$tmp" ]; then
            mv -f "$tmp" "$out"
        else
            rm -f "$tmp"
            continue
        fi
    fi
    echo "OK $id $name"
done
shopt -s nullglob
for f in "$dir"/*; do
    n="\${f##*/}"
    [ -n "\${keep[$n]}" ] || rm -f "$f"
done
`

    Process {
        id: thumbProc
        stdout: SplitParser {
            onRead: line => {
                const m = line.match(/^OK (\d+) (\S+)$/)
                if (!m) return
                const url = "file://" + root.thumbDir + "/" + m[2]
                root._thumbsSeen[m[1]] = url
                // Show new thumbnails as they're made
                if (root.thumbs[m[1]] !== url) Qt.callLater(root._publishThumbs)
            }
        }

        onExited: {
            // Exactly this job's set: drops thumbnails of deleted entries
            if (!root._sameThumbs(root._thumbsSeen)) root.thumbs = root._thumbsSeen
            if (root._thumbRerun) {
                root._thumbRerun = false
                Qt.callLater(root._startThumbs)
            }
        }
    }
}
