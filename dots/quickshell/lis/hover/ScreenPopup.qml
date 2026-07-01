import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property string icon: ""
    property string label: ""
    property bool showing: false

    anchors.top: true
    implicitWidth: 110
    implicitHeight: 40
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    visible: showing
    WlrLayershell.margins.top: 15

    Rectangle {
        anchors.centerIn: parent
        width: 95
        height: 32
        radius: 16
        color: '#121212'
        opacity: root.showing ? 1.0 : 0.0

        Behavior on opacity { NumberAnimation { duration: 150 } }

        Image {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            source: root.icon
            fillMode: Image.PreserveAspectFit

            smooth: true
            mipmap: true
            antialiasing: true
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            font.pixelSize: 14
            font.weight: Font.Medium
            color: "#e3ffffff"
        }
    }
}