import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components

// Steam's games and compatibility tools, and the changes to its files that both make
PanelFrame {
    id: root

    property bool shown: false
    readonly property Item initialFocus: root.view === "Games" ? games.searchField : viewChips
    readonly property Item viewField: viewChips
    readonly property string script: Quickshell.shellPath("scripts/proton-games.py")
    // The file chooser can't rise above the panel
    readonly property bool picking: picker.running

    property string view: "Games"
    property string status: ""
    property bool steamRunning: false
    property bool closingSteam: false
    property bool _closeAsked: false
    property var _writes: []
    property string _pendingRun: ""

    readonly property var _doneTexts: ({
        "set-launch": "Saved",
        "set-tool": "Saved",
        "add-game": "Game added",
        "remove-game": "Game removed",
        "delete-prefix": "Prefix deleted",
        "delete-tool": "Version deleted"
    })

    signal written(string command, bool ok)

    title: "Proton"
    subtitle: root.view === "Games" ? games.subtitle : versions.subtitle

    onShownChanged: {
        if (root.shown) {
            root.closingSteam = false
        } else {
            picker.running = false
            root.status = ""
        }
    }

    onSteamRunningChanged: {
        if (root.steamRunning)
            return
        root.closingSteam = false
        // Asked to close it so as to edit: ready to carry on once it's gone
        if (root._closeAsked) {
            root._closeAsked = false
            Qt.callLater(root.refocus)
        }
    }

    function refocus(): void {
        if (root.view === "Games")
            games.refocus()
        else
            versions.refocus()
    }

    function openFolder(path: string): void {
        Quickshell.execDetached(["xdg-open", path])
        root.closeRequested()
    }

    // Starts Steam with no window if it's closed; the Flatpak's isn't on PATH
    function steamUrl(url: string): void {
        Quickshell.execDetached(["sh", "-c", 'command -v steam >/dev/null && exec steam -silent "$1"; exec xdg-open "$1"', "sh", url])
    }

    // Steam shows a dialog, which the panel would cover
    function steamAction(url: string): void {
        root.steamUrl(url)
        root.closeRequested()
    }

    // After the writes: Steam wouldn't read them once it's started
    function play(runId: string): void {
        games.commit()
        root._pendingRun = runId
        root.runPending()
        root.closeRequested()
    }

    function runPending(): void {
        if (root._pendingRun === "" || writer.running || root._writes.length > 0)
            return
        root.steamUrl("steam://rungameid/" + root._pendingRun)
        root._pendingRun = ""
    }

    function closeSteam(): void {
        root.closingSteam = true
        root._closeAsked = true
        root.steamUrl("steam://exit")
    }

    function pickFile(): void {
        picker.running = true
    }

    function rescanGames(): void {
        games.rescan()
    }

    function write(args: var): void {
        root.status = ""
        root._writes = root._writes.concat([args])
        root.nextWrite()
    }

    function nextWrite(): void {
        if (writer.running || root._writes.length === 0)
            return
        writer.command = ["python3", root.script].concat(root._writes[0])
        root._writes = root._writes.slice(1)
        writer.running = true
    }

    Process {
        id: writer

        stderr: StdioCollector {
            id: writeErrors
        }

        onExited: code => {
            const command = writer.command[2]
            root.status = code === 0 ? root._doneTexts[command] : writeErrors.text.trim() || "Couldn't save"
            root.written(command, code === 0)
            root.nextWrite()
            root.runPending()
        }
    }

    // Closes the chooser when the panel closes
    Process {
        id: picker

        command: ["python3", Quickshell.shellPath("scripts/pick-image.py"), "Choose the game", "any"]

        stdout: StdioCollector {
            id: picked
        }

        onExited: code => {
            if (code === 0)
                games.setPicked(picked.text.trim())
            else if (code !== 1)
                root.status = "Couldn't open the file chooser"
        }
    }

    Timer {
        interval: 2000
        repeat: true
        triggeredOnStart: true
        running: root.shown
        onTriggered: steamCheck.running = true
    }

    Process {
        id: steamCheck

        command: ["pgrep", "-x", "steam"]
        onExited: code => root.steamRunning = code === 0
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.bottomMargin: 12
        spacing: 8

        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24
            spacing: 12

            ChipSelector {
                id: viewChips

                options: ["Games", "Versions"]
                value: root.view
                onSelected: v => root.view = v
            }

            Text {
                text: root.status
                font.pixelSize: 12
                color: Theme.textDim
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignRight
                Layout.fillWidth: true
            }

            PanelButton {
                text: "Add Game"
                visible: root.view === "Games"
                enabled: !root.steamRunning
                onClicked: games.toggleAddForm()
            }
        }

        RowLayout {
            visible: root.steamRunning
            spacing: 12
            Layout.fillWidth: true
            Layout.leftMargin: 24
            Layout.rightMargin: 24

            Text {
                text: "Steam is running. Close it to change games or delete versions, or it will overwrite the changes."
                font.pixelSize: 12
                color: Theme.textDim
                elide: Text.ElideRight
                Layout.fillWidth: true
            }

            PanelButton {
                text: root.closingSteam ? "Closing…" : "Close Steam"
                onClicked: root.closeSteam()
            }
        }

        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.view === "Games" ? 0 : 1

            ProtonGamesView {
                id: games

                panel: root
            }

            ProtonVersionsView {
                id: versions

                panel: root
            }
        }
    }
}
