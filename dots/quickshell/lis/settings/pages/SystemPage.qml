import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.settings.components
import qs.tools

ScrollView {
    id: root

    clip: true
    contentWidth: availableWidth

    // Keys from scripts/system-info.sh
    property var info: ({})
    property var gpus: []

    // Read each time the page shows
    readonly property bool open: visible && (QsWindow.window?.visible ?? false)
    onOpenChanged: if (open) reader.running = true

    function ingest(text: string): void {
        const info = {}
        const gpus = []
        for (const line of text.split("\n")) {
            const space = line.indexOf(" ")
            if (space <= 0)
                continue
            const key = line.slice(0, space)
            const value = line.slice(space + 1).trim()
            if (key === "gpu")
                gpus.push(value.match(/\[(.+)\]/)?.[1] ?? value)
            else
                info[key] = value
        }
        root.info = info
        root.gpus = gpus
    }

    Process {
        id: reader

        command: ["sh", Quickshell.shellPath("scripts/system-info.sh")]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }
    }

    ColumnLayout {
        width: root.availableWidth
        spacing: 0

        Item { height: 16 }
        SectionHeader { title: "User" }

        ValueRow { label: "Username"; value: root.info.user ?? "" }
        ValueRow { label: "Full Name"; value: root.info.name ?? "" }
        ValueRow { label: "Hostname"; value: root.info.host ?? "" }
        ValueRow { label: "Shell"; value: root.info.shell ?? "" }

        Item { height: 16 }
        SectionHeader { title: "Operating System" }

        ValueRow { label: "Distribution"; value: root.info.os ?? "" }
        ValueRow { label: "Kernel"; value: root.info.kernel ?? "" }
        ValueRow { label: "Kernel Build"; value: root.info.build ?? "" }
        ValueRow { label: "Architecture"; value: root.info.arch ?? "" }
        ValueRow { label: "Packages"; value: root.info.packages ?? "" }
        ValueRow {
            label: "Uptime"
            value: root.info.uptime ? Format.duration(Number(root.info.uptime)) : ""
        }

        Item { height: 16 }
        SectionHeader { title: "Desktop" }

        ValueRow { label: "Hyprland"; value: root.info.hyprland ?? "" }
        ValueRow { label: "Quickshell"; value: root.info.quickshell ?? "" }

        Item { height: 16 }
        SectionHeader { title: "Hardware" }

        ValueRow {
            label: "CPU"
            value: root.info.cpu ? root.info.cpu + (root.info.cores ? " · " + root.info.cores + " threads" : "") : ""
        }
        ValueRow { label: "GPU"; value: root.gpus.join(" · ") }
        ValueRow {
            label: "Memory"
            value: root.info.memory ? Format.bytes(Number(root.info.memory) * 1024) : ""
        }

        Item { height: 16 }
    }
}
