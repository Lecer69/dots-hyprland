import QtQuick

Item {
    id: root
    implicitWidth: timeText.implicitWidth + dateText.implicitWidth + 18
    implicitHeight: 22

    property color timeColor: '#cdcdcd'
    property color dateColor: '#aeaeae'

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

    Row {
        anchors.centerIn: parent
        spacing: 8

        Text {
            id: dateText
            anchors.verticalCenter: parent.verticalCenter
            font.pixelSize: 12
            font.weight: Font.Normal
            color: root.dateColor
            verticalAlignment: Text.AlignVCenter
            opacity: 0.8
        }

        Rectangle {
            width: 3
            height: 3
            radius: 1.5
            color: '#ffffff'
            anchors.verticalCenter: parent.verticalCenter
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
