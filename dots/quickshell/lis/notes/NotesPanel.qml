import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.common

// Notes: the list (newest edit first) and the open note
PanelFrame {
    id: root

    property bool shown: false
    property real selectedId: -1
    property string query: ""
    property bool deleteArmed: false
    // A private note shows once asked for, not just because the panel opened on it
    property bool revealed: false
    // Refreshed on opening
    property date now: new Date()
    property bool _loading: false
    // Shared with the title block so the lines below align
    readonly property int topRowHeight: 52
    readonly property Item initialFocus: searchInput

    readonly property var selected: notesState.notes.find(n => n.id === root.selectedId) ?? null
    readonly property bool covered: (root.selected?.private ?? false) && !root.revealed
    readonly property var visibleNotes: {
        const query = root.query.trim().toLowerCase();
        if (query === "")
            return notesState.notes;
        return notesState.notes.filter(n => n.title.toLowerCase().includes(query) || n.body.toLowerCase().includes(query));
    }
    readonly property int words: {
        const text = noteBody.text.trim();
        return text === "" ? 0 : text.split(/\s+/).length;
    }

    title: "Notes"
    subtitle: notesState.notes.length === 0 ? "" : notesState.notes.length + (notesState.notes.length === 1 ? " note" : " notes")

    onShownChanged: {
        if (root.shown) {
            root.now = new Date();
            if (!root.selected)
                root.select(notesState.notes[0]?.id ?? -1, false);
        } else {
            root.leave();
            root.deleteArmed = false;
            root.revealed = false;
        }
    }

    NotesState {
        id: notesState
    }

    // Saves the open note, and drops it if empty
    function leave(): void {
        notesState.flush();
        const note = root.selected;
        if (note && note.title.trim() === "" && note.body.trim() === "")
            notesState.remove(note.id);
    }

    function select(id: real, reveal: bool): void {
        root.revealed = reveal;
        if (id === root.selectedId)
            return;

        root.leave();
        root.selectedId = id;
        root.deleteArmed = false;
        root._loading = true;
        titleInput.text = root.selected?.title ?? "";
        noteBody.text = root.selected?.body ?? "";
        root._loading = false;
        noteBody.reset();
    }

    function step(delta: int): void {
        const list = root.visibleNotes;
        const i = list.findIndex(n => n.id === root.selectedId);
        const next = list[Math.max(0, Math.min(list.length - 1, i + delta))];
        if (next)
            root.select(next.id, true);
    }

    function newNote(): void {
        searchInput.text = "";
        root.select(notesState.add(), true);
        titleInput.forceActiveFocus();
    }

    function edited(): void {
        if (!root._loading && root.selected)
            notesState.edit(root.selectedId, titleInput.text, noteBody.text);
    }

    // Going to a private note's text shows it
    function focusBody(): void {
        root.revealed = true;
        noteBody.editorItem.forceActiveFocus();
    }

    // Leaves the text showing
    function togglePrivate(): void {
        if (!root.selected)
            return;
        root.revealed = true;
        notesState.setPrivate(root.selectedId, !root.selected.private);
    }

    // The first click arms it, the second deletes
    function deleteSelected(): void {
        if (!root.deleteArmed) {
            root.deleteArmed = true;
            disarm.restart();
            return;
        }
        const list = root.visibleNotes;
        const i = list.findIndex(n => n.id === root.selectedId);
        const next = list[i + 1] ?? list[i - 1] ?? null;
        notesState.remove(root.selectedId);
        root.select(next?.id ?? -1, false);
    }

    function _days(ms: real): int {
        const d = new Date(ms);
        const today = new Date(root.now.getFullYear(), root.now.getMonth(), root.now.getDate());
        return Math.round((today - new Date(d.getFullYear(), d.getMonth(), d.getDate())) / 86400000);
    }

    // "14:30" today, "Mon" this week, "3 Oct" this year, else "3 Oct 2025"
    function listDate(ms: real): string {
        const d = new Date(ms);
        const days = root._days(ms);
        if (days === 0)
            return Qt.formatTime(d, "hh:mm");
        if (days < 7)
            return Qt.formatDate(d, "ddd");
        return Qt.formatDate(d, d.getFullYear() === root.now.getFullYear() ? "d MMM" : "d MMM yyyy");
    }

    function editedText(ms: real): string {
        const d = new Date(ms);
        const days = root._days(ms);
        const day = days === 0 ? "today"
            : days === 1 ? "yesterday"
            : Qt.formatDate(d, d.getFullYear() === root.now.getFullYear() ? "d MMM" : "d MMM yyyy");
        return "Edited " + day + ", " + Qt.formatTime(d, "hh:mm");
    }

    Timer {
        id: disarm

        interval: 3000
        onTriggered: root.deleteArmed = false
    }

    Shortcut {
        sequence: "Ctrl+N"
        onActivated: root.newNote()
    }

    Shortcut {
        sequence: "Ctrl+F"
        onActivated: {
            searchInput.forceActiveFocus();
            searchInput.selectAll();
        }
    }

    RowLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 24

        ColumnLayout {
            Layout.preferredWidth: 280
            Layout.fillHeight: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.topRowHeight
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: 32
                    radius: 8
                    color: "#161616"

                    TextInput {
                        id: searchInput

                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        verticalAlignment: TextInput.AlignVCenter
                        color: "#e6e6e6"
                        selectionColor: "#333333"
                        selectedTextColor: "#ffffff"
                        font.pixelSize: 13
                        clip: true
                        selectByMouse: true
                        activeFocusOnTab: true
                        onTextChanged: root.query = text

                        Keys.onUpPressed: root.step(-1)
                        Keys.onDownPressed: root.step(1)
                        Keys.onReturnPressed: root.select(root.visibleNotes[0]?.id ?? root.selectedId, true)
                        Keys.onEnterPressed: root.select(root.visibleNotes[0]?.id ?? root.selectedId, true)

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            visible: searchInput.text.length === 0
                            text: "Search notes…"
                            color: "#6b6b6b"
                            font.pixelSize: 13
                        }
                    }
                }

                PanelButton {
                    Layout.alignment: Qt.AlignTop
                    implicitHeight: 32
                    text: "New"
                    onClicked: root.newNote()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#262626"
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 2
                boundsBehavior: Flickable.StopAtBounds

                // Up/Down open the next note
                function step(delta: int): void {
                    root.step(delta);
                    list.positionViewAtIndex(root.visibleNotes.findIndex(n => n.id === root.selectedId), ListView.Contain);
                }

                activeFocusOnTab: true
                Keys.onUpPressed: list.step(-1)
                Keys.onDownPressed: list.step(1)
                Keys.onReturnPressed: root.focusBody()
                Keys.onEnterPressed: root.focusBody()

                model: ScriptModel {
                    values: root.visibleNotes
                }

                delegate: Rectangle {
                    id: row

                    required property var modelData
                    readonly property bool isSelected: row.modelData.id === root.selectedId

                    width: ListView.view.width
                    height: 58
                    radius: 8
                    color: row.isSelected ? (list.activeFocus ? "#2a2a2a" : "#1f1f1f") : rowArea.containsMouse ? "#161616" : "transparent"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 3

                        Item {
                            Layout.fillHeight: true
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: row.modelData.title.trim() || "Untitled"
                                textFormat: Text.PlainText
                                elide: Text.ElideRight
                                color: row.modelData.title.trim() ? "#e6e6e6" : "#808080"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }

                            Text {
                                text: root.listDate(row.modelData.updated)
                                color: "#6b6b6b"
                                font.pixelSize: 12
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: row.modelData.private ? "Private" : row.modelData.body.replace(/\s+/g, " ").trim() || "No text"
                            textFormat: Text.PlainText
                            elide: Text.ElideRight
                            maximumLineCount: 1
                            color: "#6b6b6b"
                            font.pixelSize: 12
                        }

                        Item {
                            Layout.fillHeight: true
                        }
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.select(row.modelData.id, true)
                    }
                }

                Text {
                    anchors.centerIn: parent
                    visible: list.count === 0
                    text: root.query.trim() !== "" ? "No matching notes" : "No notes yet"
                    color: "#6b6b6b"
                    font.pixelSize: 13
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.fillHeight: true
            Layout.topMargin: root.topRowHeight + 25
            color: "#262626"
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.selected !== null
            spacing: 12

            ColumnLayout {
                Layout.fillWidth: true
                Layout.preferredHeight: root.topRowHeight
                spacing: 6

                TextInput {
                    id: titleInput

                    Layout.fillWidth: true
                    color: "#ffffff"
                    selectionColor: "#333333"
                    selectedTextColor: "#ffffff"
                    font.pixelSize: 20
                    font.weight: Font.DemiBold
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true
                    onTextEdited: root.edited()

                    Keys.onTabPressed: root.focusBody()
                    Keys.onReturnPressed: root.focusBody()
                    Keys.onEnterPressed: root.focusBody()

                    Text {
                        visible: titleInput.text.length === 0
                        text: "Title"
                        color: "#4a4a4a"
                        font: titleInput.font
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Text {
                        Layout.fillWidth: true
                        text: root.selected ? root.editedText(root.selected.updated) + "  ·  " + root.words + (root.words === 1 ? " word" : " words") : ""
                        elide: Text.ElideRight
                        color: "#6b6b6b"
                        font.pixelSize: 12
                    }

                    Text {
                        visible: noteBody.hoveredLink !== ""
                        text: "Ctrl+click to open"
                        color: "#6b6b6b"
                        font.pixelSize: 12
                    }

                    Text {
                        readonly property bool isPrivate: root.selected?.private ?? false
                        readonly property bool lit: privateArea.containsMouse || activeFocus

                        text: isPrivate ? "Private" : "Make private"
                        color: isPrivate ? (lit ? "#ffffff" : "#e6e6e6")
                            : lit ? "#dddddd" : "#666666"
                        font.pixelSize: 12

                        activeFocusOnTab: true
                        Keys.onSpacePressed: root.togglePrivate()
                        Keys.onReturnPressed: root.togglePrivate()
                        Keys.onEnterPressed: root.togglePrivate()

                        MouseArea {
                            id: privateArea

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.togglePrivate()
                        }
                    }

                    Text {
                        text: root.deleteArmed ? "Click again to delete" : "Delete"
                        color: root.deleteArmed ? "#e06c6c" : deleteArea.containsMouse || activeFocus ? "#dddddd" : "#666666"
                        font.pixelSize: 12

                        // Like the click, the first press only arms it
                        activeFocusOnTab: true
                        Keys.onSpacePressed: root.deleteSelected()
                        Keys.onReturnPressed: root.deleteSelected()
                        Keys.onEnterPressed: root.deleteSelected()

                        MouseArea {
                            id: deleteArea

                            anchors.fill: parent
                            anchors.margins: -6
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.deleteSelected()
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 1
                color: "#262626"
            }

            NoteBody {
                id: noteBody

                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: !root.covered
                placeholder: "Write something…"
                onTextChanged: root.edited()
            }

            // Covers a private note's text until asked for
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.covered

                Column {
                    anchors.centerIn: parent
                    spacing: 14

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "This note is private"
                        color: "#6b6b6b"
                        font.pixelSize: 13
                    }

                    PanelButton {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: "Show"
                        onClicked: root.focusBody()
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: root.selected === null
            spacing: 14

            Item {
                Layout.fillHeight: true
            }

            Text {
                Layout.alignment: Qt.AlignHCenter
                text: notesState.notes.length === 0 ? "Keep your first note here" : "No note open"
                color: "#6b6b6b"
                font.pixelSize: 13
            }

            PanelButton {
                Layout.alignment: Qt.AlignHCenter
                text: "New note"
                onClicked: root.newNote()
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
