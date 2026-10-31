import QtQuick

Rectangle {
    id: root

    property string text: ""

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 28
    radius: 6
    opacity: enabled ? 1 : 0.4
    color: area.pressed ? Theme.adapt("#333333") : area.containsMouse || root.activeFocus ? Theme.adapt("#2a2a2a") : Theme.border

    activeFocusOnTab: true
    Keys.onReturnPressed: root.clicked()
    Keys.onEnterPressed: root.clicked()
    Keys.onSpacePressed: root.clicked()

    Text {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: Theme.text
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
