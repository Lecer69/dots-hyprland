import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings.components
import qs.settings.data
import qs.settings
import qs.tools

// The list scrolls; the Clean button stays in view below it
Item {
    id: root

    // What SettingsPanel's PgUp/PgDn scroll, as on the other pages
    readonly property Item contentItem: scroll.contentItem

    // The settings' StackLayout sizes itself from its pages' implicit size
    implicitWidth: scroll.implicitWidth
    implicitHeight: scroll.implicitHeight + footer.height

    // Scans and cleans; runs cleanup-root.sh beside it through pkexec
    readonly property string script: Quickshell.env("HOME") + "/.config/hypr/hyprland/scripts/cleanup.sh"

    // From cleanup.sh scan, by item: {bytes, count}
    property var sizes: ({})
    // Items whose sizes are being worked out
    property var scanningItems: []
    property bool rescanAll: false
    property bool cleaning: false
    property bool confirming: false
    property string status: ""

    readonly property int keep: SettingsData.s.cleanup.pacmanKeep
    readonly property var selected: SettingsData.s.cleanup.selected

    // Ticked items with something to delete
    readonly property var cleanable: root.selected.filter(item => (root.sizes[item]?.bytes ?? 0) > 0)
    readonly property real cleanableBytes: root.cleanable.reduce((total, item) => total + root.sizes[item].bytes, 0)

    // A pending "click again" is for what the button said then
    onCleanableBytesChanged: {
        root.confirming = false
        confirmTimeout.stop()
    }

    // Sizes are worked out each time the page comes into view
    readonly property bool open: visible && (QsWindow.window?.visible ?? false)
    onOpenChanged: if (open) scan([])

    function scan(items) {
        if (scanner.running) {
            root.rescanAll = true
            return
        }
        root.scanningItems = items.length > 0 ? items : ["pacman", "coredumps", "yay", "trash", "thumbnails", "crashes"]
        scanner.command = ["bash", root.script, "scan", String(root.keep)].concat(items)
        scanner.running = true
    }

    function sizeText(item) {
        if (root.scanningItems.includes(item))
            return "…"
        const size = root.sizes[item]
        if (!size)
            return "–"
        return size.bytes > 0 ? Format.bytes(size.bytes) : "Empty"
    }

    function isSelected(item) {
        return root.selected.includes(item)
    }

    function setSelected(item, on) {
        const rest = root.selected.filter(i => i !== item)
        SettingsData.s.cleanup.selected = on ? rest.concat([item]) : rest
    }

    function clean() {
        root.status = ""
        root.cleaning = true
        cleaner.freed = root.cleanableBytes
        cleaner.command = ["bash", root.script, "clean", String(root.keep)].concat(root.cleanable)
        cleaner.running = true
    }

    Process {
        id: scanner

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.sizes = Object.assign({}, root.sizes, JSON.parse(text))
                } catch (e) {
                    console.warn("[Cleanup] unreadable scan output:", e)
                }
            }
        }

        onExited: {
            root.scanningItems = []
            if (root.rescanAll) {
                root.rescanAll = false
                root.scan([])
            }
        }
    }

    // pkexec exits 126 when its password prompt is dismissed and 127 when
    // it isn't allowed; cleanup.sh deletes nothing then. It exits 3 when it
    // left a cache alone because pacman or yay was using it
    Process {
        id: cleaner

        property real freed: 0

        stderr: StdioCollector {
            id: cleanerErrors
        }

        onExited: code => {
            root.cleaning = false
            if (code === 0)
                root.status = "Freed " + Format.bytes(freed)
            else if (code === 126 || code === 127)
                root.status = "Cancelled, nothing was deleted"
            else if (code === 1)
                root.status = "Some files couldn't be deleted"
            else if (code === 3)
                root.status = "Done, but skipped a cache pacman or yay was using"
            else
                root.status = "Cleanup failed"
            if (code !== 0 && cleanerErrors.text.trim() !== "")
                console.warn("[Cleanup]", cleanerErrors.text.trim())
            root.scan([])
        }
    }

    Timer {
        id: confirmTimeout
        interval: 4000
        onTriggered: root.confirming = false
    }

    ScrollView {
        id: scroll
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: footer.top }
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0

            Item { height: 16 }
            SectionHeader { title: "System · asks for your password" }

            CheckRow {
                label: "Pacman Cache"
                description: "Versions past the last " + root.keep + " of each package, and removed packages"
                value: root.sizeText("pacman")
                checked: root.isSelected("pacman")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("pacman", v)
            }
            SettingRow {
                label: "Keep Versions"
                description: "Cached versions of each package kept for rolling back (2)"
                IntSlider {
                    from: 0; to: 3; stepSize: 1
                    value: SettingsData.s.cleanup.pacmanKeep
                    onChanged: v => {
                        SettingsData.s.cleanup.pacmanKeep = v
                        root.scan(["pacman"])
                    }
                }
            }
            CheckRow {
                label: "Core Dumps"
                description: "Crashes saved by systemd" + ((root.sizes.coredumps?.count ?? 0) > 0 ? " (" + root.sizes.coredumps.count + ")" : "")
                value: root.sizeText("coredumps")
                checked: root.isSelected("coredumps")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("coredumps", v)
            }

            Item { height: 16 }
            SectionHeader { title: "Files" }

            CheckRow {
                label: "AUR Build Cache"
                description: "yay's copies of removed packages, and build files of installed ones"
                value: root.sizeText("yay")
                checked: root.isSelected("yay")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("yay", v)
            }
            CheckRow {
                label: "Trash"
                description: "Permanently deletes everything in the trash"
                value: root.sizeText("trash")
                checked: root.isSelected("trash")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("trash", v)
            }
            CheckRow {
                label: "Thumbnails"
                description: "File previews, made again when needed"
                value: root.sizeText("thumbnails")
                checked: root.isSelected("thumbnails")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("thumbnails", v)
            }
            CheckRow {
                label: "Quickshell Crash Reports"
                description: "Reports and dumps from past shell crashes"
                value: root.sizeText("crashes")
                checked: root.isSelected("crashes")
                enabled: !root.cleaning
                onToggled: v => root.setSelected("crashes", v)
            }

            Item { height: 16 }
        }
    }

    Item {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: footerColumn.implicitHeight + 25

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
            height: 1
            color: "#262626"
        }

        Column {
            id: footerColumn
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 0.5 }
            spacing: 6

            // The first click asks; a second one within 4 s deletes
            Rectangle {
                id: cleanButton

                readonly property bool usable: !root.cleaning && root.scanningItems.length === 0 && root.cleanableBytes > 0

                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                width: cleanLabel.implicitWidth + 24
                radius: 6
                opacity: usable || root.cleaning ? 1 : 0.4
                color: !usable ? "#1f1f1f"
                     : cleanArea.pressed ? "#333333"
                     : cleanArea.containsMouse ? "#2a2a2a"
                     : "#1f1f1f"

                Text {
                    id: cleanLabel
                    anchors.centerIn: parent
                    text: root.cleaning ? "Cleaning…"
                        : root.confirming ? "Click again to delete " + Format.bytes(root.cleanableBytes)
                        : "Clean selected · " + Format.bytes(root.cleanableBytes)
                    font { pixelSize: 12; weight: Font.Medium }
                    color: "#e6e6e6"
                }

                MouseArea {
                    id: cleanArea
                    anchors.fill: parent
                    enabled: cleanButton.usable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.confirming) {
                            root.confirming = true
                            confirmTimeout.restart()
                            return
                        }
                        root.confirming = false
                        confirmTimeout.stop()
                        root.clean()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: root.status !== ""
                text: root.status
                font.pixelSize: 12
                color: "#6b6b6b"
            }
        }
    }
}
