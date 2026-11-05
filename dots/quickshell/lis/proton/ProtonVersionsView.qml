import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components
import qs.tools

// Compatibility tools: Steam looks after its own, the others are installed from their GitHub releases
ColumnLayout {
    id: root

    required property var panel

    readonly property string subtitle: root._loaded ? root.installed.length + " installed" : ""

    property var installed: []
    // What Steam has but hasn't installed
    property var steamTools: []
    property var releases: []
    property bool checkFailed: false
    property bool _loaded: false
    property string jobLabel: ""
    property string jobStep: ""
    property string _jobDone: ""
    property bool _cancelled: false

    readonly property bool busy: installer.running
    readonly property var available: root.releases.filter(release => !root.isInstalled(release))
        .map(release => Object.assign({ kind: "release" }, release)).concat(root.steamTools)
    readonly property bool active: root.visible && root.panel.shown

    onActiveChanged: {
        if (root.active) {
            reader.running = true
            releaseReader.running = true
        }
    }

    function isInstalled(release: var): bool {
        return root.installed.some(tool => tool.name.includes(release.label) || tool.path.split("/").pop().includes(release.label))
    }

    function updateFor(tool: var): var {
        if (tool.kind !== "custom" || tool.source === "")
            return null
        return root.releases.find(release => release.source === tool.source && !root.isInstalled(release)) ?? null
    }

    function details(tool: var): string {
        const users = tool.users === 1 ? "1 game" : tool.users + " games"
        const update = root.updateFor(tool)
        const kind = tool.kind === "steam" ? "Updated by Steam" : tool.kind === "system" ? "System package" : "Custom"
        return [kind, Format.bytes(tool.size), tool.users > 0 ? users : "", update ? update.label + " is out" : ""]
            .filter(part => part !== "").join(" · ")
    }

    function install(source: string, label: string, oldTool: string): void {
        root.panel.status = ""
        root.jobLabel = label
        root.jobStep = "Starting…"
        root._jobDone = ""
        root._cancelled = false
        installer.command = ["python3", root.panel.script, "install", source].concat(oldTool !== "" ? [oldTool] : [])
        installer.running = true
        // The button that started it turns off
        root.refocus()
    }

    function jobLine(line: string): void {
        const parts = line.split(" ")
        if (parts[0] === "download")
            root.jobStep = "Downloading " + Math.round(Number(parts[1]) * 100) + "%"
        else if (parts[0] === "verify")
            root.jobStep = "Checking the download…"
        else if (parts[0] === "extract")
            root.jobStep = "Unpacking…"
        else if (parts[0] === "switch")
            root.jobStep = "Moving the games over…"
        else if (parts[0] === "done")
            root._jobDone = parts.slice(1).join(" ")
    }

    function refocus(): void {
        root.panel.viewField.forceActiveFocus()
    }

    Connections {
        target: root.panel

        function onWritten(command: string, ok: bool): void {
            if (command === "delete-tool") {
                reader.running = true
                root.refocus()
            }
        }
    }

    Process {
        id: reader

        command: ["python3", root.panel.script, "list-tools"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text)
                    root.installed = list.installed
                    root.steamTools = list.available
                    root._loaded = true
                } catch (e) {
                    console.warn("[Proton] unreadable tool list:", e)
                }
            }
        }
    }

    Process {
        id: releaseReader

        command: ["python3", root.panel.script, "releases"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(text)
                    root.releases = list.releases
                    root.checkFailed = list.error
                } catch (e) {
                    root.checkFailed = true
                }
            }
        }
    }

    // Goes on while the panel is closed
    Process {
        id: installer

        stdout: SplitParser {
            onRead: line => root.jobLine(line)
        }

        stderr: StdioCollector {
            id: installErrors
        }

        onExited: code => {
            const message = code === 0 ? "Installed " + root._jobDone
                : root._cancelled ? "Cancelled, the download carries on next time"
                : installErrors.text.trim() || "Couldn't install " + root.jobLabel
            root.panel.status = message
            if (!root.panel.shown)
                Quickshell.execDetached(["notify-send", "Proton", message])
            reader.running = true
            root.panel.rescanGames()
        }
    }

    spacing: 8

    RowLayout {
        visible: root.busy
        spacing: 12
        Layout.fillWidth: true
        Layout.leftMargin: 24
        Layout.rightMargin: 24

        Text {
            text: root.jobLabel + " · " + root.jobStep
            font.pixelSize: 12
            color: Theme.text
            elide: Text.ElideRight
            Layout.fillWidth: true
        }

        PanelButton {
            text: "Cancel"
            onClicked: {
                root._cancelled = true
                installer.running = false
            }
        }
    }

    ScrollView {
        id: scroll

        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: 8
        Layout.rightMargin: 8
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0

            SectionHeader {
                title: "Installed"
            }

            Repeater {
                model: root.installed

                SettingRow {
                    id: tool

                    required property var modelData
                    readonly property var update: root.updateFor(tool.modelData)

                    label: tool.modelData.label
                    description: root.details(tool.modelData)

                    Row {
                        spacing: 6

                        ListButton {
                            text: "Update"
                            above: root.panel.viewField
                            visible: tool.update !== null
                            enabled: !root.busy && !root.panel.steamRunning
                            onClicked: root.install(tool.update.source, tool.update.label, tool.modelData.name)
                        }

                        ListButton {
                            text: "Folder"
                            above: root.panel.viewField
                            onClicked: root.panel.openFolder(tool.modelData.path)
                        }

                        ConfirmButton {
                            visible: tool.modelData.kind === "custom"
                            above: root.panel.viewField
                            enabled: !root.busy && !root.panel.steamRunning
                            idleText: "Delete"
                            confirmText: tool.modelData.users > 0
                                ? "Click again, " + tool.modelData.users + (tool.modelData.users === 1 ? " game uses it" : " games use it")
                                : "Click again"
                            onConfirmed: root.panel.write(["delete-tool", tool.modelData.name])
                        }

                        // Steam asks first
                        ListButton {
                            text: "Uninstall"
                            above: root.panel.viewField
                            visible: tool.modelData.kind === "steam"
                            onClicked: root.panel.steamAction("steam://uninstall/" + tool.modelData.appId)
                        }
                    }
                }
            }

            SectionHeader {
                title: releaseReader.running ? "Available · checking…"
                    : root.checkFailed ? "Available · couldn't reach GitHub"
                    : "Available"
                Layout.topMargin: 8
            }

            Repeater {
                model: root.available

                SettingRow {
                    id: choice

                    required property var modelData

                    label: choice.modelData.label
                    description: choice.modelData.kind === "steam" ? "From Steam"
                        : choice.modelData.source + " · " + Format.bytes(choice.modelData.size) + " download"

                    ListButton {
                        text: "Install"
                        above: root.panel.viewField
                        enabled: choice.modelData.kind === "steam" || !root.busy
                        onClicked: {
                            if (choice.modelData.kind === "steam")
                                root.panel.steamAction("steam://install/" + choice.modelData.appId)
                            else
                                root.install(choice.modelData.source, choice.modelData.label, "")
                        }
                    }
                }
            }

            Item {
                implicitHeight: 8
            }
        }
    }
}
