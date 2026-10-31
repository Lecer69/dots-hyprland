import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components
import qs.tools

PanelFrame {
    id: root

    property bool shown: false

    property bool showAll: false
    property string sortKey: "cpu"
    property string filterText: ""
    property int selectedPid: -1
    property bool selectedOwned: false

    property var _rows: []
    property var _prevTicks: ({})
    property real _prevTotal: 0
    property int _shownCount: 0
    readonly property Item initialFocus: search

    function formatMemory(bytes: real): string {
        if (bytes >= 1073741824) return (bytes / 1073741824).toFixed(1) + " GB"
        return Math.round(bytes / 1048576) + " MB"
    }

    // CPU share of the whole machine since the last sample, from /proc/<pid>/stat ticks
    function ingest(text: string): void {
        const parts = text.split("===\n")
        if (parts.length < 4) return

        const uid = parseInt(parts[0])
        const total = parts[1].trim().split(/\s+/).slice(1, 9).map(Number).reduce((a, b) => a + b, 0)

        // "1000 /proc/1234"
        const owners = {}
        for (const line of parts[2].split("\n")) {
            const space = line.indexOf(" ")
            if (space > 0) owners[line.slice(space + 7)] = parseInt(line.slice(0, space))
        }

        const elapsed = root._prevTotal > 0 ? total - root._prevTotal : 0
        const ticks = {}
        const rows = []
        for (const line of parts[3].split("\n")) {
            // The name is in parentheses and may contain spaces
            const open = line.indexOf("(")
            const close = line.lastIndexOf(")")
            if (open < 0 || close < open) continue

            const pid = parseInt(line.slice(0, open))
            const fields = line.slice(close + 2).split(" ")
            const used = Number(fields[11]) + Number(fields[12])
            const prev = root._prevTicks[pid]
            ticks[pid] = used
            rows.push({
                pid: pid,
                name: line.slice(open + 1, close),
                cpu: elapsed > 0 && prev !== undefined ? Math.max(0, (used - prev) / elapsed * 100) : 0,
                memory: Number(fields[21]) * 4096,
                own: owners[pid] === uid
            })
        }

        root._prevTicks = ticks
        root._prevTotal = total
        root._rows = rows
        refreshModel()
    }

    // In place, so the list keeps its scroll position
    function refreshModel(): void {
        const query = root.filterText.toLowerCase()
        const rows = root._rows.filter(r => (root.showAll || r.own)
            && (query === "" || r.name.toLowerCase().includes(query) || String(r.pid).startsWith(query)))

        const compare = {
            cpu: (a, b) => (b.cpu - a.cpu) || (b.memory - a.memory),
            memory: (a, b) => b.memory - a.memory,
            name: (a, b) => a.name.localeCompare(b.name),
            pid: (a, b) => a.pid - b.pid
        }[root.sortKey]
        rows.sort(compare)

        for (let i = 0; i < rows.length; i++) {
            if (i < procModel.count) procModel.set(i, rows[i])
            else procModel.append(rows[i])
        }
        if (procModel.count > rows.length)
            procModel.remove(rows.length, procModel.count - rows.length)

        root._shownCount = rows.length

        // The selection follows the pid and goes with the process
        const selected = rows.find(r => r.pid === root.selectedPid)
        if (!selected) root.selectedPid = -1
        root.selectedOwned = selected ? selected.own : false
    }

    function sendSignal(name: string): void {
        if (root.selectedPid > 0)
            Quickshell.execDetached(["kill", "-" + name, String(root.selectedPid)])
    }

    // Up from the first row goes back to the search
    function stepSelection(delta: int): void {
        let index = -1
        for (let i = 0; i < procModel.count; i++) {
            if (procModel.get(i).pid === root.selectedPid) {
                index = i
                break
            }
        }
        if (index === 0 && delta < 0) {
            search.forceActiveFocus()
            return
        }
        const next = index < 0 ? 0 : Math.max(0, Math.min(procModel.count - 1, index + delta))
        if (next >= procModel.count)
            return
        const row = procModel.get(next)
        root.selectedPid = row.pid
        root.selectedOwned = row.own
        list.positionViewAtIndex(next, ListView.Contain)
    }

    onSortKeyChanged: refreshModel()
    onFilterTextChanged: refreshModel()
    onShowAllChanged: refreshModel()
    onShownChanged: {
        if (shown) return
        // Start over, so the first figures don't average over the closed time
        root.selectedPid = -1
        root._prevTotal = 0
        root._prevTicks = {}
    }

    title: "Task Manager"
    subtitle: root._shownCount + " processes"

    Timer {
        interval: 2000
        repeat: true
        running: root.shown
        triggeredOnStart: true
        onTriggered: if (!sampler.running) sampler.running = true
    }

    Process {
        id: sampler

        command: ["sh", "-c", "id -u; echo ===; head -1 /proc/stat; echo ===; stat -c '%u %n' /proc/[0-9]* 2>/dev/null; echo ===; cat /proc/[0-9]*/stat 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: root.ingest(text)
        }
    }

    SystemStats {
        id: systemStats

        running: root.shown
    }

    ListModel {
        id: procModel
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: 8
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
        spacing: 16

        SystemMeters {
            Layout.fillWidth: true
            columns: 2
            stats: systemStats
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Rectangle {
                Layout.fillWidth: true
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
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true
                    onTextChanged: root.filterText = text

                    Keys.onDownPressed: {
                        list.forceActiveFocus()
                        if (root.selectedPid === -1)
                            root.stepSelection(1)
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search processes…"
                        color: Theme.textDim
                        font.pixelSize: 13
                    }
                }
            }

            ChipSelector {
                options: ["Mine", "All"]
                value: root.showAll ? "All" : "Mine"
                onSelected: v => root.showAll = v === "All"
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 4

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 10
                Layout.rightMargin: 10
                spacing: 0

                SortHeader {
                    Layout.fillWidth: true
                    label: "Name"
                    key: "name"
                    alignRight: false
                }

                SortHeader {
                    Layout.preferredWidth: 70
                    label: "PID"
                    key: "pid"
                }

                SortHeader {
                    Layout.preferredWidth: 70
                    label: "CPU"
                    key: "cpu"
                }

                SortHeader {
                    Layout.preferredWidth: 90
                    label: "Memory"
                    key: "memory"
                }
            }

            ListView {
                id: list

                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                model: procModel
                spacing: 1
                boundsBehavior: Flickable.StopAtBounds

                activeFocusOnTab: true
                Keys.onUpPressed: root.stepSelection(-1)
                Keys.onDownPressed: root.stepSelection(1)
                Keys.onDeletePressed: event => {
                    if (root.selectedOwned)
                        root.sendSignal(event.modifiers & Qt.ShiftModifier ? "KILL" : "TERM")
                }

                delegate: Rectangle {
                    id: row

                    required property int pid
                    required property string name
                    required property real cpu
                    required property real memory
                    required property bool own

                    readonly property bool selected: root.selectedPid === row.pid

                    width: list.width
                    height: 30
                    radius: 6
                    color: row.selected ? (list.activeFocus ? Theme.adapt("#2a2a2a") : Theme.border) : rowArea.containsMouse ? Theme.hover : "transparent"

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 10
                        anchors.rightMargin: 10
                        spacing: 0

                        Text {
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                            text: row.name
                            color: row.selected ? Theme.adapt("#ffffff") : row.own ? Theme.text : Theme.adapt("#999999")
                            font.pixelSize: 13
                        }

                        Text {
                            Layout.preferredWidth: 70
                            horizontalAlignment: Text.AlignRight
                            text: row.pid
                            color: Theme.textDim
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.preferredWidth: 70
                            horizontalAlignment: Text.AlignRight
                            text: row.cpu.toFixed(1) + "%"
                            color: Theme.adapt("#999999")
                            font.pixelSize: 12
                        }

                        Text {
                            Layout.preferredWidth: 90
                            horizontalAlignment: Text.AlignRight
                            text: root.formatMemory(row.memory)
                            color: Theme.adapt("#999999")
                            font.pixelSize: 12
                        }
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            root.selectedPid = row.pid
                            root.selectedOwned = row.own
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                color: Theme.textDim
                font.pixelSize: 12
                text: {
                    if (root.selectedPid === -1) return "Select a process"
                    return root.selectedOwned ? "PID " + root.selectedPid : "PID " + root.selectedPid + " belongs to another user"
                }
            }

            PanelButton {
                enabled: root.selectedPid !== -1 && root.selectedOwned
                text: "End process"
                onClicked: root.sendSignal("TERM")
            }

            PanelButton {
                enabled: root.selectedPid !== -1 && root.selectedOwned
                text: "Kill"
                onClicked: root.sendSignal("KILL")
            }
        }
    }

    component SortHeader: Text {
        id: header

        property string label: ""
        property string key: ""
        property bool alignRight: true

        horizontalAlignment: alignRight ? Text.AlignRight : Text.AlignLeft
        text: label + (root.sortKey === key ? " ▾" : "")
        color: root.sortKey === key || header.activeFocus ? Theme.text : headerArea.containsMouse ? Theme.adapt("#cccccc") : Theme.textDim
        font.underline: header.activeFocus

        activeFocusOnTab: true
        Keys.onSpacePressed: root.sortKey = header.key
        Keys.onReturnPressed: root.sortKey = header.key
        Keys.onEnterPressed: root.sortKey = header.key
        font.pixelSize: 12
        font.weight: Font.Medium

        MouseArea {
            id: headerArea

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.sortKey = header.key
        }
    }
}
