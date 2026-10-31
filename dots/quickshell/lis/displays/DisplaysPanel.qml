import QtQuick
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components

PanelFrame {
    id: root

    property bool shown: false

    // Editable copy of the monitors, and what Hyprland is using
    property var monitors: []
    property string appliedState: ""
    property int selected: 0

    // After Apply: reverted unless kept before the countdown ends
    property bool confirming: false
    property int countdown: 0
    property string backupLua: ""
    property string backupConf: ""

    // Monitor name -> shown image, and -> its hyprpaper.conf block
    property var wallpapers: ({})
    property var wallpaperBlocks: ({})
    property string wallpaperError: ""
    // The panel hides meanwhile, so the file chooser isn't under it
    property string pickingFor: ""
    readonly property bool picking: pickingFor !== ""
    // Picked images are copied here, so moving the original is safe
    readonly property string wallpaperDir: Quickshell.env("HOME") + "/.config/lis/wallpapers"

    readonly property bool changed: appliedState !== "" && JSON.stringify(monitors) !== appliedState
    readonly property var current: monitors[selected] ?? null
    readonly property int enabledCount: monitors.filter(m => m.enabled).length
    readonly property var transformNames: ["Normal", "90°", "180°", "270°"]

    function load(): void {
        if (!reader.running) reader.running = true
        if (!wallpaperReader.running) wallpaperReader.running = true
        hyprpaperConf.reload()
        root.wallpaperError = ""
    }

    function ingest(text: string): void {
        let list
        try {
            list = JSON.parse(text)
        } catch (e) {
            return
        }
        const monitors = list.map(m => {
            const modes = m.availableModes.map(s => s.replace("Hz", ""))
            const mode = modes.find(s => {
                const [size, rate] = s.split("@")
                return size === m.width + "x" + m.height && Math.abs(Number(rate) - m.refreshRate) < 0.05
            }) ?? (m.width > 0 ? m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2) : (modes[0] ?? "1920x1080@60.00"))
            return {
                name: m.name,
                description: m.description,
                mode: mode,
                modes: modes,
                x: m.x,
                y: m.y,
                scale: m.scale,
                transform: m.transform,
                enabled: !m.disabled,
                vrr: m.vrr,
                tenBit: (m.currentFormat ?? "").includes("2101010")
            }
        }).sort((a, b) => (a.x - b.x) || (a.y - b.y))
        root.monitors = monitors
        root.appliedState = JSON.stringify(monitors)
        if (root.selected >= monitors.length) root.selected = 0
    }

    // The mode divided by the scale, turned by rotation
    function logicalSize(m: var): var {
        const size = m.mode.split("@")[0].split("x").map(Number)
        let w = size[0] / m.scale
        let h = size[1] / m.scale
        if (m.transform % 2 === 1) [w, h] = [h, w]
        return { w: Math.round(w), h: Math.round(h) }
    }

    function update(changes: var): void {
        const copy = root.monitors.slice()
        copy[root.selected] = Object.assign({}, copy[root.selected], changes)
        root.monitors = copy
    }

    // Snaps to the others' edges, then shifts the layout to start at 0,0
    function place(i: int, x: real, y: real): void {
        const me = logicalSize(root.monitors[i])
        let bestX = x
        let bestY = y
        let distX = 120
        let distY = 120
        root.monitors.forEach((o, j) => {
            if (j === i || !o.enabled) return
            const os = logicalSize(o)
            for (const cx of [o.x + os.w, o.x - me.w, o.x, o.x + os.w - me.w]) {
                if (Math.abs(cx - x) < distX) {
                    distX = Math.abs(cx - x)
                    bestX = cx
                }
            }
            for (const cy of [o.y, o.y + os.h - me.h, o.y + os.h, o.y - me.h]) {
                if (Math.abs(cy - y) < distY) {
                    distY = Math.abs(cy - y)
                    bestY = cy
                }
            }
        })
        const copy = root.monitors.map((m, j) => j === i ? Object.assign({}, m, { x: Math.round(bestX), y: Math.round(bestY) }) : m)
        const active = copy.filter(m => m.enabled)
        const minX = Math.min(...active.map(m => m.x))
        const minY = Math.min(...active.map(m => m.y))
        root.monitors = copy.map(m => Object.assign({}, m, { x: m.x - minX, y: m.y - minY }))
    }

    function resolutions(m: var): var {
        const pixels = s => s.split("x").reduce((a, b) => a * Number(b), 1)
        return [...new Set(m.modes.map(s => s.split("@")[0]))].sort((a, b) => pixels(b) - pixels(a))
    }

    function rates(m: var, size: string): var {
        return m.modes.filter(s => s.startsWith(size + "@")).map(s => s.split("@")[1]).sort((a, b) => Number(b) - Number(a))
    }

    // nwg-displays' format: monitors by description
    function luaConfig(): string {
        const blocks = root.monitors.map(m => {
            const props = ['    output = "desc:' + m.description.replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"']
            if (!m.enabled) {
                props.push("    disabled = true")
            } else {
                props.push('    mode = "' + m.mode + '"', '    position = "' + m.x + "x" + m.y + '"', "    scale = " + m.scale)
                if (m.tenBit) props.push("    bitdepth = 10")
                props.push("    vrr = " + (m.vrr ? 1 : 0))
                if (m.transform !== 0) props.push("    transform = " + m.transform)
            }
            return "hl.monitor({\n" + props.join(",\n") + "\n})"
        })
        return ["-- Generated by the lis Displays panel. Do not edit manually.", ""].concat(blocks).join("\n") + "\n"
    }

    function confConfig(): string {
        const lines = ["# Generated by the lis Displays panel. Do not edit manually.", ""]
        for (const m of root.monitors) {
            const name = "desc:" + m.description
            if (!m.enabled) {
                lines.push("monitor=" + name + ",disable")
                continue
            }
            let line = "monitor=" + name + "," + m.mode + "," + m.x + "x" + m.y + "," + m.scale
            if (m.tenBit) line += ",bitdepth,10"
            lines.push(line + ",vrr," + (m.vrr ? 1 : 0))
            if (m.transform !== 0) lines.push("monitor=" + name + ",transform," + m.transform)
        }
        return lines.join("\n") + "\n"
    }

    function wallpaperOf(name: string): string {
        const path = root.wallpapers[name] ?? root.wallpaperBlocks[name]?.path ?? ""
        return path.replace(/^~(?=\/|$)/, Quickshell.env("HOME"))
    }

    function fileUrl(path: string): string {
        return path === "" ? "" : "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    // Without the prefix its copy got
    function wallpaperName(path: string): string {
        const file = path.split("/").pop()
        return path.startsWith(root.wallpaperDir + "/") ? file.replace(/^[^.]*\.\d+\./, "") : file
    }

    // "MONITOR: /path" lines from hyprctl hyprpaper listactive
    function ingestWallpapers(text: string): void {
        const map = {}
        for (const line of text.split("\n")) {
            const m = /^([^\s:]+):\s*(\/.*)$/.exec(line.trim())
            if (m) map[m[1]] = m[2]
        }
        root.wallpapers = map
    }

    function parseWallpaperBlocks(conf: string): var {
        const map = {}
        let block = null
        for (const raw of conf.split("\n")) {
            const line = raw.trim()
            if (/^wallpaper\s*\{/.test(line)) {
                block = {}
            } else if (block && line === "}") {
                if (block.monitor) map[block.monitor] = block
                block = null
            } else if (block) {
                const m = /^(\w+)\s*=\s*(.*)$/.exec(line)
                if (m) block[m[1]] = m[2]
            }
        }
        return map
    }

    // The monitor's block pointing at path; a missing block is added at the end
    function withWallpaper(conf: string, monitor: string, path: string): string {
        const lines = conf === "" ? [] : conf.replace(/\n$/, "").split("\n")
        let start = -1
        for (let i = 0; i < lines.length; i++) {
            const line = lines[i].trim()
            if (/^wallpaper\s*\{/.test(line)) {
                start = i
            } else if (start >= 0 && line === "}") {
                const block = lines.slice(start + 1, i)
                const named = block.find(l => /^\s*monitor\s*=\s*(.*?)\s*$/.exec(l)?.[1] === monitor)
                if (named !== undefined) {
                    const at = block.findIndex(l => /^\s*path\s*=/.test(l))
                    const line = (at >= 0 ? block[at] : named).match(/^\s*/)[0] + "path = " + path
                    if (at >= 0) lines[start + 1 + at] = line
                    else lines.splice(i, 0, line)
                    return lines.join("\n") + "\n"
                }
                start = -1
            }
        }
        if (lines.length > 0 && lines[lines.length - 1].trim() !== "") lines.push("")
        lines.push("wallpaper {", "    monitor = " + monitor, "    path = " + path, "    fit_mode = cover", "}")
        return lines.join("\n") + "\n"
    }

    function pickWallpaper(): void {
        if (!root.current || root.picking) return
        root.wallpaperError = ""
        root.pickingFor = root.current.name
        picker.running = true
    }

    function cancelPick(): void {
        root.pickingFor = ""
        picker.running = false
    }

    function setWallpaper(monitor: string, source: string): void {
        // hyprctl takes "monitor,path,fit", so no commas in the name
        const name = source.split("/").pop().replace(/[,\n]/g, "_")
        const dot = name.lastIndexOf(".")
        const short = dot > 0 ? name.slice(0, dot).slice(0, 60) + name.slice(dot).slice(0, 8) : name.slice(0, 60)
        const fit = root.wallpaperBlocks[monitor]?.fit_mode ?? ""
        root.wallpaperError = ""
        setter.monitor = monitor
        setter.copy = root.wallpaperDir + "/" + monitor + "." + Date.now() + "." + short
        setter.command = ["sh", "-c", setter.script, "sh", root.wallpaperDir, source, setter.copy, monitor,
            ["contain", "cover", "tile", "fill"].includes(fit) ? fit : "cover"]
        setter.running = true
    }

    // Once hyprpaper shows it, so it survives a restart
    function saveWallpaper(monitor: string, path: string): void {
        root.wallpapers = Object.assign({}, root.wallpapers, { [monitor]: path })
        hyprpaperConf.readable = false
        hyprpaperConf.reload()
        hyprpaperConf.waitForJob()
        if (!hyprpaperConf.readable) {
            root.wallpaperError = "Couldn't read hyprpaper.conf: set until hyprpaper restarts"
            return
        }
        hyprpaperConf.setText(root.withWallpaper(hyprpaperConf.missing ? "" : hyprpaperConf.text(), monitor, path))
        root.wallpaperBlocks = root.parseWallpaperBlocks(hyprpaperConf.text())
    }

    function apply(): void {
        luaFile.reload()
        luaFile.waitForJob()
        confFile.reload()
        confFile.waitForJob()
        root.backupLua = luaFile.text()
        root.backupConf = confFile.text()

        luaFile.setText(root.luaConfig())
        confFile.setText(root.confConfig())
        Quickshell.execDetached(["hyprctl", "reload"])
        console.log("[Displays] Applied; reverting in 15s unless kept")

        root.confirming = true
        root.countdown = 15
        countdownTimer.restart()
    }

    function keep(): void {
        countdownTimer.stop()
        root.confirming = false
        root.load()
    }

    function revert(): void {
        countdownTimer.stop()
        root.confirming = false
        luaFile.setText(root.backupLua)
        confFile.setText(root.backupConf)
        Quickshell.execDetached(["hyprctl", "reload"])
        console.log("[Displays] Reverted")
        reloadTimer.restart()
    }

    onShownChanged: if (shown && !confirming) load()
    onSelectedChanged: wallpaperError = ""

    title: "Displays"
    subtitle: monitors.length + (monitors.length === 1 ? " display" : " displays")
    implicitHeight: headerHeight + 8 + content.implicitHeight + 24

    Process {
        id: reader

        command: ["hyprctl", "monitors", "all", "-j"]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }
    }

    Process {
        id: wallpaperReader

        command: ["hyprctl", "hyprpaper", "listactive"]

        stdout: StdioCollector {
            onStreamFinished: root.ingestWallpapers(text)
        }
    }

    FileView {
        id: hyprpaperConf

        // Whether the text can be rewritten; a missing file counts as empty
        property bool readable: false
        property bool missing: false

        path: Quickshell.env("HOME") + "/.config/hypr/hyprpaper.conf"
        blockWrites: true
        printErrors: false

        onLoaded: {
            readable = true
            missing = false
            root.wallpaperBlocks = root.parseWallpaperBlocks(text())
        }
        onLoadFailed: error => {
            missing = error === FileViewError.FileNotFound
            readable = missing
            root.wallpaperBlocks = ({})
        }
    }

    // Prints the picked path; exit 1 is cancelled
    Process {
        id: picker

        command: ["python3", Quickshell.shellPath("scripts/pick-image.py"), "Choose wallpaper for " + root.pickingFor]

        stdout: StdioCollector {
            id: pickedPath
        }
        stderr: StdioCollector {
            id: pickerErrors
        }

        onExited: code => {
            const monitor = root.pickingFor
            root.pickingFor = ""
            if (monitor === "") return
            if (code === 0) {
                root.setWallpaper(monitor, pickedPath.text.trim())
            } else if (code !== 1) {
                console.warn("[Displays] file chooser failed:", pickerErrors.text.trim())
                root.wallpaperError = "Couldn't open the file chooser"
            }
        }
    }

    // Copy, show it, then drop the older copies; hyprpaper takes non-images too
    Process {
        id: setter

        property string monitor: ""
        property string copy: ""
        readonly property string script: `
exec 2>&1
dir=$1 src=$2 copy=$3 monitor=$4 fit=$5
if command -v file >/dev/null && ! file -b --mime-type -- "$src" | grep -q '^image/'; then
    echo "Not an image"; exit 1
fi
mkdir -p "$dir" && cp -- "$src" "$copy" || exit 1
hyprctl hyprpaper wallpaper "$monitor,$copy,$fit" || { rm -f -- "$copy"; exit 1; }
for f in "$dir/$monitor".*; do
    [ "$f" = "$copy" ] || rm -f -- "$f"
done
`

        stdout: StdioCollector {
            id: setterOutput
        }

        onExited: code => {
            if (code === 0) {
                root.saveWallpaper(setter.monitor, setter.copy)
            } else {
                console.warn("[Displays] setting the wallpaper failed:", setterOutput.text.trim())
                root.wallpaperError = setterOutput.text.trim().split("\n").pop() || "Couldn't set the wallpaper"
            }
        }
    }

    FileView {
        id: luaFile

        path: Quickshell.env("HOME") + "/.config/hypr/monitors.lua"
        blockWrites: true
        printErrors: false
    }

    FileView {
        id: confFile

        path: Quickshell.env("HOME") + "/.config/hypr/monitors.conf"
        blockWrites: true
        printErrors: false
    }

    Timer {
        id: countdownTimer

        interval: 1000
        repeat: true
        onTriggered: {
            root.countdown--
            if (root.countdown <= 0) root.revert()
        }
    }

    // Once Hyprland has applied the old config
    Timer {
        id: reloadTimer

        interval: 1500
        onTriggered: root.load()
    }

    ColumnLayout {
        id: content

        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 16

        // Drag a monitor to move it; gives up height on short screens
        Rectangle {
            id: canvas

            readonly property var bounds: {
                let minX = Infinity
                let minY = Infinity
                let maxX = -Infinity
                let maxY = -Infinity
                for (const m of root.monitors) {
                    if (!m.enabled) continue
                    const s = root.logicalSize(m)
                    minX = Math.min(minX, m.x)
                    minY = Math.min(minY, m.y)
                    maxX = Math.max(maxX, m.x + s.w)
                    maxY = Math.max(maxY, m.y + s.h)
                }
                if (minX === Infinity) return { x: 0, y: 0, w: 1920, h: 1080 }
                return { x: minX, y: minY, w: maxX - minX, h: maxY - minY }
            }
            readonly property real factor: Math.min((width - 48) / bounds.w, (height - 48) / bounds.h)
            readonly property real offsetX: (width - bounds.w * factor) / 2
            readonly property real offsetY: (height - bounds.h * factor) / 2

            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 352
            Layout.minimumHeight: 160
            radius: 8
            color: Theme.adapt("#131313")

            Repeater {
                model: root.monitors

                Rectangle {
                    id: tile

                    required property var modelData
                    required property int index

                    readonly property var size: root.logicalSize(modelData)
                    readonly property bool isSelected: index === root.selected

                    visible: modelData.enabled
                    x: canvas.offsetX + (modelData.x - canvas.bounds.x) * canvas.factor
                    y: canvas.offsetY + (modelData.y - canvas.bounds.y) * canvas.factor
                    width: size.w * canvas.factor
                    height: size.h * canvas.factor
                    radius: 6
                    color: tile.isSelected ? Theme.adapt("#262626") : Theme.adapt("#1c1c1c")
                    z: tileArea.drag.active ? 1 : 0

                    // Cropped like hyprpaper's cover fit, dimmed so the name reads
                    Image {
                        id: tileWallpaper

                        anchors.fill: parent
                        source: root.fileUrl(root.wallpaperOf(tile.modelData.name))
                        sourceSize.width: 512
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        visible: false
                        layer.enabled: true
                    }

                    Rectangle {
                        id: tileMask

                        anchors.fill: parent
                        radius: tile.radius
                        color: "white"
                        visible: false
                        layer.enabled: true
                    }

                    MultiEffect {
                        anchors.fill: tileWallpaper
                        source: tileWallpaper
                        maskEnabled: true
                        maskSource: tileMask
                        visible: tileWallpaper.status === Image.Ready
                        opacity: tile.isSelected ? 0.5 : 0.3
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: tile.radius
                        color: "transparent"
                        border.width: 1
                        border.color: tile.isSelected ? Theme.text : Theme.adapt("#2e2e2e")
                    }

                    Column {
                        anchors.centerIn: parent
                        spacing: 2

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.name
                            color: tile.isSelected ? Theme.adapt("#ffffff") : Theme.adapt("#999999")
                            font.pixelSize: 12
                            font.weight: Font.Medium
                        }

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.mode.split("@")[0].replace("x", "×")
                            color: Theme.textDim
                            font.pixelSize: 11
                        }
                    }

                    MouseArea {
                        id: tileArea

                        anchors.fill: parent
                        enabled: !root.confirming
                        drag.target: tile
                        cursorShape: drag.active ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                        onPressed: root.selected = tile.index
                        onReleased: {
                            if (!drag.active) return
                            root.place(tile.index,
                                canvas.bounds.x + (tile.x - canvas.offsetX) / canvas.factor,
                                canvas.bounds.y + (tile.y - canvas.offsetY) / canvas.factor)
                        }
                    }
                }
            }
        }

        // Turned-off monitors can't be dragged, so they're picked here
        Row {
            visible: root.monitors.length > root.enabledCount
            spacing: 4

            Repeater {
                model: root.monitors

                Rectangle {
                    required property var modelData
                    required property int index

                    visible: !modelData.enabled
                    width: offLabel.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: index === root.selected ? Theme.adapt("#262626") : "transparent"

                    Text {
                        id: offLabel

                        anchors.centerIn: parent
                        text: parent.modelData.name + " (off)"
                        color: parent.index === root.selected ? Theme.adapt("#ffffff") : Theme.adapt("#808080")
                        font.pixelSize: 12
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selected = parent.index
                    }
                }
            }
        }

        ColumnLayout {
            visible: root.current !== null
            enabled: !root.confirming
            Layout.fillWidth: true
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.current ? root.current.name : ""
                    color: Theme.text
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }

                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: root.current ? root.current.description : ""
                    color: Theme.textDim
                    font.pixelSize: 12
                }

                ToggleSwitch {
                    id: enabledToggle

                    checked: root.current ? root.current.enabled : false
                    onToggled: v => {
                        // At least one monitor stays on
                        if (v || root.enabledCount > 1) root.update({ enabled: v })
                        enabledToggle.checked = Qt.binding(() => root.current ? root.current.enabled : false)
                    }
                }
            }

            ColumnLayout {
                visible: root.current !== null && root.current.enabled
                Layout.fillWidth: true
                spacing: 14

                SettingLabel { text: "Resolution" }

                ChipSelector {
                    Layout.fillWidth: true
                    options: root.current ? root.resolutions(root.current) : []
                    value: root.current ? root.current.mode.split("@")[0] : ""
                    onSelected: size => root.update({ mode: size + "@" + root.rates(root.current, size)[0] })
                }

                SettingLabel { text: "Refresh rate" }

                ChipSelector {
                    Layout.fillWidth: true
                    options: root.current ? root.rates(root.current, root.current.mode.split("@")[0]).map(r => r + " Hz") : []
                    value: root.current ? root.current.mode.split("@")[1] + " Hz" : ""
                    onSelected: rate => root.update({ mode: root.current.mode.split("@")[0] + "@" + rate.replace(" Hz", "") })
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24

                    ColumnLayout {
                        spacing: 8

                        SettingLabel { text: "Scale" }

                        ChipSelector {
                            options: ["1", "1.25", "1.5", "2"]
                            value: root.current ? String(root.current.scale) : ""
                            onSelected: v => root.update({ scale: Number(v) })
                        }
                    }

                    ColumnLayout {
                        spacing: 8

                        SettingLabel { text: "Rotation" }

                        ChipSelector {
                            options: root.transformNames
                            value: root.current ? (root.transformNames[root.current.transform] ?? "") : ""
                            onSelected: v => root.update({ transform: root.transformNames.indexOf(v) })
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 24

                    RowLayout {
                        spacing: 12

                        ToggleSwitch {
                            id: vrrToggle

                            checked: root.current ? root.current.vrr : false
                            onToggled: v => {
                                root.update({ vrr: v })
                                vrrToggle.checked = Qt.binding(() => root.current ? root.current.vrr : false)
                            }
                        }

                        Text {
                            text: "Variable refresh rate"
                            color: Theme.text
                            font.pixelSize: 13
                        }
                    }

                    RowLayout {
                        spacing: 12

                        ToggleSwitch {
                            id: tenBitToggle

                            checked: root.current ? root.current.tenBit : false
                            onToggled: v => {
                                root.update({ tenBit: v })
                                tenBitToggle.checked = Qt.binding(() => root.current ? root.current.tenBit : false)
                            }
                        }

                        Text {
                            text: "10-bit color"
                            color: Theme.text
                            font.pixelSize: 13
                        }
                    }
                }

                SettingLabel { text: "Wallpaper" }

                // Applied right away, not with Apply
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    // Cropped like hyprpaper's cover fit
                    Item {
                        readonly property var size: root.current ? root.logicalSize(root.current) : ({ w: 16, h: 9 })

                        Layout.preferredHeight: 54
                        Layout.preferredWidth: Math.round(Math.max(30, Math.min(120, 54 * size.w / size.h)))

                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            color: Theme.hover
                        }

                        Image {
                            id: thumb

                            readonly property string path: root.current ? root.wallpaperOf(root.current.name) : ""

                            anchors.fill: parent
                            source: root.fileUrl(path)
                            sourceSize.width: 256
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true
                            visible: false
                            layer.enabled: true
                        }

                        Rectangle {
                            id: thumbMask

                            anchors.fill: parent
                            radius: 6
                            color: "white"
                            visible: false
                            layer.enabled: true
                        }

                        MultiEffect {
                            anchors.fill: thumb
                            source: thumb
                            maskEnabled: true
                            maskSource: thumbMask
                            visible: thumb.status === Image.Ready
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideMiddle
                            text: thumb.path !== "" ? root.wallpaperName(thumb.path) : "No wallpaper"
                            textFormat: Text.PlainText
                            color: thumb.path !== "" ? Theme.text : Theme.textDim
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: root.wallpaperError !== ""
                            elide: Text.ElideRight
                            text: root.wallpaperError
                            textFormat: Text.PlainText
                            color: Theme.adapt("#e06c6c")
                            font.pixelSize: 12
                        }
                    }

                    PanelButton {
                        enabled: !setter.running
                        text: "Change…"
                        onClicked: root.pickWallpaper()
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 6

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.confirming ? "Keep these settings? Reverting in " + root.countdown + "s"
                    : root.changed ? "Changes not applied yet" : ""
                color: root.confirming ? Theme.text : Theme.textDim
                font.pixelSize: 12
            }

            PanelButton {
                visible: root.confirming
                text: "Revert"
                onClicked: root.revert()
            }

            PanelButton {
                visible: root.confirming
                text: "Keep"
                onClicked: root.keep()
            }

            PanelButton {
                visible: !root.confirming
                enabled: root.changed
                text: "Reset"
                onClicked: root.monitors = JSON.parse(root.appliedState)
            }

            PanelButton {
                visible: !root.confirming
                enabled: root.changed
                text: "Apply"
                onClicked: root.apply()
            }
        }
    }

    component SettingLabel: Text {
        color: Theme.textDim
        font.pixelSize: 12
        font.weight: Font.Medium
    }
}
