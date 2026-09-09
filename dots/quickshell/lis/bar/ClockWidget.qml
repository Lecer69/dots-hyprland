import QtQuick
import qs.settings.data

Item {
    id: root
    property bool vertical: false

    property color timeColor: '#cdcdcd'
    property color dateColor: '#aeaeae'
    property bool showDate: !SettingsData.s.bar.showClockOnly && !root.vertical
    // Left bar: read bottom-to-top; right bar: top-to-bottom
    readonly property int rotationAngle: root.vertical
        ? (SettingsData.s.bar.position === "left" ? -90 : 90)
        : 0

    // Horizontal: content-width row. Vertical: rotated, so the footprint is
    // swapped (text runs top to bottom, keeping the bar narrow).
    implicitWidth: root.vertical ? contentHost.height : contentHost.width
    implicitHeight: root.vertical ? contentHost.width : contentHost.height

    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const now = new Date()

            let h = now.getHours()
            const m = now.getMinutes().toString().padStart(2, "0")

            const ampm = h >= 12 ? "PM" : "AM"
            h = h % 12
            if (h === 0) h = 12
            h = h.toString().padStart(2, "0")

            timeText.text = h + ":" + m + " " + ampm

            const days = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
            const months = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]

            const monthNumber = (now.getMonth() + 1).toString().padStart(2, "0")

            dateText.text =
                days[now.getDay()] + " " +
                now.getDate().toString().padStart(2, "0") + " " +
                months[now.getMonth()] + " (" + monthNumber + ")"
        }
    }

    Item {
        id: contentHost
        width: row.implicitWidth
        height: 22
        anchors.centerIn: parent
        rotation: root.rotationAngle

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: calendarWindow.shown = !calendarWindow.shown

            Row {
                id: row
                anchors.centerIn: parent
                spacing: 8
                opacity: parent.containsMouse ? 0.75 : 1.0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 100
                    }
                }

                Text {
                    id: dateText
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 12
                    font.weight: Font.Normal
                    color: root.dateColor
                    verticalAlignment: Text.AlignVCenter
                    opacity: 0.8
                    visible: root.showDate
                    width: root.showDate ? implicitWidth : 0
                }

                Rectangle {
                    width: 3
                    height: 3
                    radius: 1.5
                    color: '#ffffff'
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.showDate
                }

                Text {
                    id: timeText
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: root.timeColor
                    verticalAlignment: Text.AlignVCenter
                    font.letterSpacing: 0.5
                }
            }
        }
    }
}