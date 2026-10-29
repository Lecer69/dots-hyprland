import QtQuick

Rectangle {
    id: root

    property string text: ""

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: 6
    opacity: enabled ? 1 : 0.4
    color: area.pressed ? "#333333" : area.containsMouse ? "#2a2a2a" : "#1f1f1f"

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: "#e6e6e6"
        font.pixelSize: 12
        font.weight: Font.Medium
    }

    MouseArea {
        id: area

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
