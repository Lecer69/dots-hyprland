import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components

// The games: running them, their folders, what Steam runs them with, adding and removing them
ColumnLayout {
    id: root

    required property var panel

    readonly property Item searchField: search
    readonly property string subtitle: root._scanned ? root.shownCount + (root.shownCount === 1 ? " game" : " games") : ""

    // From the script, sorted by name
    property var games: []
    // { name, label }
    property var tools: []
    property string filterText: ""
    property string editingId: ""
    property bool adding: false
    property string _output: ""
    property bool _scanned: false
    // The open editor
    property Item _editor: null

    readonly property int shownCount: root.games.filter(game => root.matches(game, root.filterText)).length
    readonly property bool panelShown: root.panel.shown

    onPanelShownChanged: {
        if (root.panelShown) {
            scanner.running = true
        } else {
            // Hiding the window doesn't finish the typing
            root.commit()
            root.editingId = ""
            root.adding = false
            search.text = ""
        }
    }

    function matches(game: var, filter: string): bool {
        const words = filter.trim().toLowerCase()
        return words === "" || game.name.toLowerCase().includes(words) || game.id.includes(words)
    }

    function details(game: var): string {
        return [game.id, game.prefix !== "" ? game.proton : "No prefix", game.steam ? "" : "Non-Steam"]
            .filter(part => part !== "").join(" · ")
    }

    function commit(): void {
        root._editor?.commit()
    }

    function rescan(): void {
        root._output = ""
        scanner.running = true
    }

    function toggleEditor(id: string, button: Item): void {
        root.commit()
        button.forceActiveFocus()
        root.editingId = root.editingId === id ? "" : id
    }

    function toggleAddForm(): void {
        root.adding = !root.adding
        scroll.contentItem.contentY = 0
        if (!root.adding)
            search.forceActiveFocus()
    }

    function setPicked(path: string): void {
        addForm.item?.setExe(path)
    }

    function refocus(): void {
        if (root._editor)
            root._editor.focusFirst()
        else
            search.forceActiveFocus()
    }

    Connections {
        target: root.panel

        function onWritten(command: string, ok: bool): void {
            // Rows show what was saved; they're read again on the next open
            if (ok && (command === "set-launch" || command === "set-tool")) {
                root._output = ""
                return
            }
            if (ok && command === "add-game")
                root.adding = false
            if (ok && command === "remove-game")
                root.editingId = ""
            if (ok && (command === "add-game" || command === "remove-game"))
                search.forceActiveFocus()
            root.rescan()
        }
    }

    // Below the fold on the lower rows; the page is laid out by then
    Timer {
        id: reveal

        interval: 30
        onTriggered: {
            if (!root._editor)
                return
            const flick = scroll.contentItem
            const bottom = root._editor.mapToItem(flick.contentItem, 0, root._editor.height).y + 8
            if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(bottom - flick.height, Math.max(0, flick.contentHeight - flick.height))
        }
    }

    Process {
        id: scanner

        command: ["python3", root.panel.script]

        stdout: StdioCollector {
            onStreamFinished: {
                root._scanned = true
                // Same games: the rows stay, and the focus with them
                if (text === root._output)
                    return
                root._output = text
                try {
                    const list = JSON.parse(text)
                    root.tools = list.tools
                    root.games = list.games
                } catch (e) {
                    root.games = []
                    console.warn("[Proton] unreadable scan output:", e)
                }
            }
        }
    }

    spacing: 8

    Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: 24
        Layout.rightMargin: 24
        implicitHeight: 32
        radius: 8
        color: Theme.hover

        TextInput {
            id: search

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            verticalAlignment: TextInput.AlignVCenter
            color: Theme.text
            selectionColor: Theme.adapt("#333333")
            selectedTextColor: Theme.adapt("#ffffff")
            font.pixelSize: 13
            clip: true
            selectByMouse: true
            activeFocusOnTab: true
            onTextChanged: root.filterText = text

            // Escape empties it first, then closes the panel
            Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape && search.text !== ""
            Keys.onEscapePressed: search.text = ""
            Keys.onDownPressed: search.nextItemInFocusChain(true)?.forceActiveFocus(Qt.TabFocusReason)

            Text {
                anchors.verticalCenter: parent.verticalCenter
                visible: search.text.length === 0
                text: "Search games…"
                color: Theme.textDim
                font.pixelSize: 13
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

            Loader {
                id: addForm

                active: root.adding
                visible: active
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                Layout.topMargin: 8
                Layout.bottomMargin: 18
                onLoaded: item.focusFirst()

                sourceComponent: ProtonAddGame {
                    tools: root.tools
                    steamRunning: root.panel.steamRunning
                    onBrowseRequested: root.panel.pickFile()
                    onCancelRequested: root.toggleAddForm()
                    onAddRequested: (name, exe, options, tool) => root.panel.write(["add-game", name, exe, options, tool])
                }
            }

            Text {
                visible: root._scanned && root.shownCount === 0
                text: root.games.length === 0 ? "No Steam games found" : "No games found"
                font.pixelSize: 13
                color: Theme.textDim
                Layout.leftMargin: 16
                Layout.topMargin: 8
            }

            Repeater {
                model: root.games

                ColumnLayout {
                    id: game

                    required property var modelData
                    property string launch: game.modelData.launch
                    property string tool: game.modelData.tool

                    visible: root.matches(game.modelData, root.filterText)
                    spacing: 0
                    Layout.fillWidth: true

                    SettingRow {
                        label: game.modelData.name
                        description: root.details(game.modelData)

                        Row {
                            spacing: 6

                            ListButton {
                                id: playButton

                                text: "Play"
                                above: search
                                enabled: game.modelData.runnable
                                KeyNavigation.right: prefixButton
                                onClicked: root.panel.play(game.modelData.runId)
                            }

                            ListButton {
                                id: prefixButton

                                text: "Prefix"
                                above: search
                                enabled: game.modelData.prefix !== ""
                                KeyNavigation.left: playButton
                                KeyNavigation.right: installButton
                                onClicked: root.panel.openFolder(game.modelData.prefix)
                            }

                            ListButton {
                                id: installButton

                                text: "Install"
                                above: search
                                enabled: game.modelData.install !== ""
                                KeyNavigation.left: prefixButton
                                KeyNavigation.right: editButton
                                onClicked: root.panel.openFolder(game.modelData.install)
                            }

                            ListButton {
                                id: editButton

                                text: "Edit"
                                above: search
                                enabled: game.modelData.id !== ""
                                KeyNavigation.left: installButton
                                onClicked: root.toggleEditor(game.modelData.id, editButton)
                            }
                        }
                    }

                    Loader {
                        active: root.editingId !== "" && root.editingId === game.modelData.id
                        visible: active
                        Layout.fillWidth: true
                        Layout.leftMargin: 16
                        Layout.rightMargin: 16
                        Layout.topMargin: 4
                        Layout.bottomMargin: 14
                        onLoaded: {
                            root._editor = item
                            item.focusFirst()
                            reveal.restart()
                        }

                        sourceComponent: ProtonGameEditor {
                            launch: game.launch
                            tool: game.tool
                            tools: root.tools
                            steamRunning: root.panel.steamRunning
                            steam: game.modelData.steam
                            hasPrefix: game.modelData.prefix !== ""
                            onLaunchEdited: options => {
                                game.launch = options
                                root.panel.write(["set-launch", game.modelData.id, options])
                            }
                            onToolChosen: name => {
                                game.tool = name
                                root.panel.write(["set-tool", game.modelData.id, name])
                            }
                            onDeletePrefixRequested: root.panel.write(["delete-prefix", game.modelData.id])
                            onRemoveRequested: {
                                if (game.modelData.steam)
                                    root.panel.steamAction("steam://uninstall/" + game.modelData.id)
                                else
                                    root.panel.write(["remove-game", game.modelData.id])
                            }
                        }
                    }
                }
            }
        }
    }
}
