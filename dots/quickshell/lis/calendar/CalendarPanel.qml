import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]
    readonly property var dayNames: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    readonly property var dayNamesFull: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property date selectedDate: today

    readonly property string monthLabel: monthNames[viewMonth] + " " + viewYear

    readonly property var cells: {
        const first = new Date(viewYear, viewMonth, 1)
        const startOffset = first.getDay()
        const result = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(viewYear, viewMonth, 1 - startOffset + i)
            result.push({
                day: d.getDate(),
                inMonth: d.getMonth() === viewMonth,
                isToday: d.getFullYear() === today.getFullYear()
                    && d.getMonth() === today.getMonth()
                    && d.getDate() === today.getDate(),
                isSelected: d.getFullYear() === selectedDate.getFullYear()
                    && d.getMonth() === selectedDate.getMonth()
                    && d.getDate() === selectedDate.getDate(),
                date: d
            })
        }
        return result
    }

    function shiftMonth(delta: int): void {
        let m = viewMonth + delta
        let y = viewYear
        if (m < 0) {
            m = 11
            y--
        } else if (m > 11) {
            m = 0
            y++
        }
        viewMonth = m
        viewYear = y
    }

    function goToday(): void {
        const t = new Date()
        today = t
        selectedDate = t
        viewYear = t.getFullYear()
        viewMonth = t.getMonth()
    }

    // Refresh "today" highlight at midnight
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: {
            const t = new Date()
            if (t.toDateString() !== root.today.toDateString())
                root.today = t
        }
    }

    // Click shield: absorb clicks on empty panel space so the
    // backdrop in CalendarWindow doesn't close the window
    MouseArea {
        anchors.fill: parent
        onClicked: mouse.accepted = true
    }

    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Calendar"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#dddddd"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: closeHover.containsMouse ? "#252525" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: "#888888"
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    Rectangle {
        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: "#222222"
    }

    ColumnLayout {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 20
        spacing: 14

        // Month navigation
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Rectangle {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: prevHover.containsMouse ? "#252525" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.pixelSize: 18
                    color: "#888888"
                }

                MouseArea {
                    id: prevHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(-1)
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                text: root.monthLabel
                font.pixelSize: 14
                font.weight: Font.DemiBold
                color: "#dddddd"
            }

            Rectangle {
                anchors.right: nextBtn.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: todayLabel.implicitWidth + 20
                height: 28
                radius: 8
                color: todayHover.containsMouse ? "#252525" : "#1a1a1a"
                border.color: "#2a2a2a"
                border.width: 1

                Text {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    color: "#888888"
                    font.pixelSize: 12
                }

                MouseArea {
                    id: todayHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }

                Behavior on color {
                    ColorAnimation {
                        duration: 100
                    }
                }
            }

            Rectangle {
                id: nextBtn

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28
                radius: 14
                color: nextHover.containsMouse ? "#252525" : "transparent"

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: 18
                    color: "#888888"
                }

                MouseArea {
                    id: nextHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.shiftMonth(1)
                }
            }
        }

        // Weekday header
        Row {
            Layout.fillWidth: true
            spacing: 4

            Repeater {
                model: root.dayNames

                Item {
                    required property string modelData

                    width: (dayGrid.width - 6 * 4) / 7
                    height: 16

                    Text {
                        anchors.centerIn: parent
                        text: parent.modelData
                        font.pixelSize: 11
                        color: "#666666"
                        font.letterSpacing: 0.5
                    }
                }
            }
        }

        // Day grid
        Grid {
            id: dayGrid

            Layout.fillWidth: true
            columns: 7
            rowSpacing: 4
            columnSpacing: 4

            Repeater {
                model: root.cells

                Rectangle {
                    id: cell

                    required property var modelData

                    width: (dayGrid.width - 6 * dayGrid.columnSpacing) / 7
                    height: 44
                    radius: 12
                    border.width: 1
                    border.color: modelData.isSelected && !modelData.isToday ? "#555555" : "transparent"
                    color: modelData.isToday
                        ? "#beffffff"
                        : cellHover.containsMouse ? "#1c1c1c" : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 100
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        font.pixelSize: 13
                        font.weight: cell.modelData.isToday ? Font.DemiBold : Font.Normal
                        color: cell.modelData.isToday
                            ? "#111111"
                            : cell.modelData.inMonth ? "#cfcfcf" : "#3f3f3f"
                    }

                    MouseArea {
                        id: cellHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.selectedDate = cell.modelData.date
                    }
                }
            }
        }

        Item {
            Layout.fillHeight: true
        }

        // Selected date footer
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: "#141414"
            border.color: "#222222"
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: root.dayNamesFull[root.selectedDate.getDay()] + ", "
                    + root.selectedDate.getDate() + " "
                    + root.monthNames[root.selectedDate.getMonth()] + " "
                    + root.selectedDate.getFullYear()
                color: "#777777"
                font.pixelSize: 12
            }
        }

    }

}