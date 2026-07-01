import QtQuick
import qs.tools

Item {
    id: root

    width: row.width
    height: 16

    Row {
        id: row
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: 6

        Image {
            source: "../icons/memory.svg"
            width: 16
            height: 16
            fillMode: Image.PreserveAspectFit
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            font.pixelSize: 13
            color: '#acacac'

            text: Math.round((ResourceUsage.memoryUsedPercentage || 0) * 100) + "%"
        }
    }
}