pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.bar
import qs.common
import qs.phone
import qs.todo

// Daily tasks and undone important ones, over the power plan, battery and phone
PanelFrame {
    id: root

    property bool shown: false

    readonly property var daily: TodoService.listed(TodoService.dailyList)
    // Daily ones are listed already
    readonly property var important: TodoService.tasks.filter(t => t.important && !t.done && t.list !== TodoService.dailyList)
    // Arrows start from here, as nothing is picked on opening
    readonly property Item initialFocus: root

    signal todoRequested()

    title: "Today"

    onShownChanged: {
        if (root.shown) {
            root.subtitle = Qt.formatDate(new Date(), "dddd, d MMMM");
            flick.contentY = 0;
            powerPlan.running = true;
        }
    }

    Keys.onDownPressed: KeyNav.step(root, true, "sidebarTasks")
    Keys.onUpPressed: KeyNav.step(root, false, "sidebarTasks")

    // Stays empty without power-profiles-daemon
    Process {
        id: powerPlan

        property string name: ""

        command: ["sh", "-c", "powerprofilesctl get 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: powerPlan.name = text.trim()
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 20
        spacing: 14

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                id: flick

                anchors.fill: parent
                contentWidth: width
                contentHeight: tasks.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: tasks

                    width: flick.width
                    spacing: 2

                    SectionTitle {
                        width: tasks.width
                        visible: root.daily.length > 0
                        title: "Daily"
                        count: root.daily.filter(t => t.done).length + "/" + root.daily.length
                    }

                    Repeater {
                        // Keyed, so a ticked row keeps the keyboard
                        model: ScriptModel {
                            values: root.daily
                            objectProp: "id"
                        }

                        delegate: TaskRow {
                            required property var modelData

                            width: tasks.width
                            task: modelData
                        }
                    }

                    SectionTitle {
                        width: tasks.width
                        visible: root.important.length > 0
                        topPadding: root.daily.length > 0 ? 14 : 0
                        title: "Important"
                        count: root.important.length
                    }

                    Repeater {
                        model: ScriptModel {
                            values: root.important
                            objectProp: "id"
                        }

                        delegate: TaskRow {
                            required property var modelData

                            width: tasks.width
                            task: modelData
                            leavesWhenDone: true
                            fallback: root
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.daily.length === 0 && root.important.length === 0
                text: "Nothing for today"
                color: Theme.textDim
                font.pixelSize: 13
            }
        }

        Text {
            Layout.leftMargin: 8
            text: "Open To-do"
            color: todoArea.containsMouse || activeFocus ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
            font.pixelSize: 12

            activeFocusOnTab: true
            Keys.onSpacePressed: root.todoRequested()
            Keys.onReturnPressed: root.todoRequested()
            Keys.onEnterPressed: root.todoRequested()

            MouseArea {
                id: todoArea

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.todoRequested()
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            visible: powerRow.visible || batteryRow.visible || phoneRow.visible
            color: Theme.adapt("#262626")
        }

        InfoRow {
            id: powerRow

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: powerPlan.name !== ""
            label: "Power Plan"
            value: ({ "performance": "Performance", "balanced": "Balanced", "power-saver": "Power Saver" })[powerPlan.name] ?? powerPlan.name
        }

        InfoRow {
            id: batteryRow

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: BatteryData.available
            label: "Battery"
            value: BatteryData.percent + "%" + (BatteryData.charging ? " · Charging" : "")
        }

        InfoRow {
            id: phoneRow

            Layout.fillWidth: true
            Layout.leftMargin: 8
            Layout.rightMargin: 8
            visible: PhoneService.enabled && PhoneService.phone !== null
            label: "Phone"
            value: {
                if (!PhoneService.connected)
                    return "Not connected";
                const stats = PhoneService.stats;
                return stats ? stats.battery_percent + "%" + (stats.charging ? " · Charging" : "") + " · " + stats.network : "Connected";
            }
        }
    }
}
