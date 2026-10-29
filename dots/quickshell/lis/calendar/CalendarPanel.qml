import QtQuick
import QtQuick.Layouts

Rectangle {
    id: root

    signal closeRequested()

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    readonly property var monthNames: ["January","February","March","April","May","June","July","August","September","October","November","December"]
    readonly property var dayNames: ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    readonly property var dayNamesFull: ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    property date today: new Date()
    property int viewYear: today.getFullYear()
    property int viewMonth: today.getMonth()
    property date selectedDate: today

    readonly property string monthLabel: monthNames[viewMonth] + " " + viewYear
    readonly property var selectedNotes: calendarState.notesFor(selectedDate)

    property bool newNoteYearly: false

    CalendarState {
        id: calendarState
    }

    function addNote(): void {
        calendarState.addNote(selectedDate, noteInput.text, newNoteYearly)
        noteInput.text = ""
        newNoteYearly = false
    }

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

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Calendar"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#ffffff"
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            font.pixelSize: 12
            color: closeHover.containsMouse ? "#dddddd" : "#666666"

            MouseArea {
                id: closeHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    ColumnLayout {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 14

        // Month navigation
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 28

            Item {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: "‹"
                    font.pixelSize: 18
                    color: prevHover.containsMouse ? "#ffffff" : "#808080"
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
                color: "#e6e6e6"
            }

            Rectangle {
                anchors.right: nextBtn.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                width: todayLabel.implicitWidth + 20
                height: 28
                radius: 6
                color: todayHover.pressed ? "#333333" : todayHover.containsMouse ? "#2a2a2a" : "#1f1f1f"

                Text {
                    id: todayLabel

                    anchors.centerIn: parent
                    text: "Today"
                    color: "#e6e6e6"
                    font.pixelSize: 12
                    font.weight: Font.Medium
                }

                MouseArea {
                    id: todayHover

                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.goToday()
                }
            }

            Item {
                id: nextBtn

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: 28
                height: 28

                Text {
                    anchors.centerIn: parent
                    text: "›"
                    font.pixelSize: 18
                    color: nextHover.containsMouse ? "#ffffff" : "#808080"
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
                        color: "#6b6b6b"
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
                    radius: 8
                    color: modelData.isToday ? "#e6e6e6"
                        : modelData.isSelected ? "#1f1f1f"
                        : cellHover.containsMouse ? "#161616" : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: cell.modelData.day
                        font.pixelSize: 13
                        font.weight: cell.modelData.isToday ? Font.DemiBold : Font.Normal
                        color: cell.modelData.isToday
                            ? "#0f0f0f"
                            : cell.modelData.inMonth ? "#e6e6e6" : "#4a4a4a"
                    }

                    // Has-notes marker
                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        anchors.bottomMargin: 6
                        width: 4
                        height: 4
                        radius: 2
                        visible: calendarState.hasNotes(cell.modelData.date)
                        color: cell.modelData.isToday
                            ? "#0f0f0f"
                            : cell.modelData.inMonth ? "#808080" : "#3a3a3a"
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

        // Selected date + note count
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 18

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: root.dayNamesFull[root.selectedDate.getDay()] + ", "
                    + root.selectedDate.getDate() + " "
                    + root.monthNames[root.selectedDate.getMonth()] + " "
                    + root.selectedDate.getFullYear()
                color: "#6b6b6b"
                font.pixelSize: 12
                font.weight: Font.Medium
            }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: root.selectedNotes.length > 0
                    ? root.selectedNotes.length + (root.selectedNotes.length === 1 ? " note" : " notes")
                    : ""
                color: "#6b6b6b"
                font.pixelSize: 12
            }
        }

        // Notes for the selected date
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Flickable {
                anchors.fill: parent
                contentWidth: width
                contentHeight: notesColumn.height
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                flickableDirection: Flickable.VerticalFlick

                Column {
                    id: notesColumn

                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.selectedNotes

                        Rectangle {
                            id: noteRow

                            required property var modelData

                            width: notesColumn.width
                            height: Math.max(36, noteText.implicitHeight + 16)
                            radius: 8
                            color: noteHover.hovered ? "#161616" : "transparent"

                            HoverHandler {
                                id: noteHover
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 10
                                anchors.rightMargin: 6
                                spacing: 10

                                Rectangle {
                                    Layout.preferredWidth: 6
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: "#808080"
                                }

                                Text {
                                    id: noteText

                                    Layout.fillWidth: true
                                    text: noteRow.modelData.text
                                    color: "#e6e6e6"
                                    font.pixelSize: 13
                                    wrapMode: Text.Wrap
                                }

                                // Yearly toggle, shown when set or on hover
                                Rectangle {
                                    Layout.preferredWidth: yearlyLabel.implicitWidth + 16
                                    Layout.preferredHeight: 22
                                    radius: 6
                                    opacity: noteRow.modelData.yearly || noteHover.hovered ? 1 : 0
                                    color: noteRow.modelData.yearly ? "#262626" : "transparent"

                                    Text {
                                        id: yearlyLabel

                                        anchors.centerIn: parent
                                        text: "Yearly"
                                        font.pixelSize: 11
                                        color: noteRow.modelData.yearly ? "#ffffff"
                                             : yearlyHover.containsMouse ? "#cccccc" : "#808080"
                                    }

                                    MouseArea {
                                        id: yearlyHover

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: calendarState.toggleYearly(noteRow.modelData.id)
                                    }
                                }

                                // Delete
                                Item {
                                    Layout.preferredWidth: 26
                                    Layout.preferredHeight: 26

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✕"
                                        font.pixelSize: 11
                                        color: delHover.containsMouse ? "#dddddd" : "#666666"
                                    }

                                    MouseArea {
                                        id: delHover

                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: calendarState.removeNote(noteRow.modelData.id)
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: root.selectedNotes.length === 0
                text: "No notes for this day"
                color: "#6b6b6b"
                font.pixelSize: 13
            }
        }

        // Add note input
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 8
            color: "#161616"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                TextInput {
                    id: noteInput

                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    color: "#e6e6e6"
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Add a note…"
                        color: "#6b6b6b"
                        font.pixelSize: 13
                        visible: noteInput.text.length === 0
                    }

                    Keys.onReturnPressed: root.addNote()
                    Keys.onEnterPressed: root.addNote()
                }

                Rectangle {
                    Layout.preferredWidth: newYearlyLabel.implicitWidth + 16
                    Layout.preferredHeight: 22
                    radius: 6
                    color: root.newNoteYearly ? "#262626" : "transparent"

                    Text {
                        id: newYearlyLabel

                        anchors.centerIn: parent
                        text: "Yearly"
                        font.pixelSize: 11
                        color: root.newNoteYearly ? "#ffffff"
                             : newYearlyHover.containsMouse ? "#cccccc" : "#808080"
                    }

                    MouseArea {
                        id: newYearlyHover

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.newNoteYearly = !root.newNoteYearly
                    }
                }

                Text {
                    text: "+"
                    font.pixelSize: 16
                    color: addHover.containsMouse ? "#ffffff" : "#808080"

                    MouseArea {
                        id: addHover

                        anchors.fill: parent
                        anchors.margins: -6
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.addNote()
                    }
                }
            }
        }

    }

}