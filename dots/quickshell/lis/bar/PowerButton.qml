import QtQuick
import Quickshell

Item {
    id: root

    property var otherMenu: null
    property var screen: null

    // Compatibility with the otherMenu wiring in Bar.qml: the dialog
    // exposes the same isOpen API as the old DropdownMenu
    readonly property var menu: powerDialog

    width: 16
    height: 16
    smooth: true

    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: "../icons/power.svg"
        fillMode: Image.PreserveAspectFit
        smooth: true
        antialiasing: true
        opacity: menuBtn.containsMouse ? 0.7 : 1.0
    }

    MouseArea {
        id: menuBtn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (root.otherMenu) root.otherMenu.isOpen = false
            powerDialog.targetScreen = root.screen
            powerDialog.isOpen = !powerDialog.isOpen
        }
    }
}