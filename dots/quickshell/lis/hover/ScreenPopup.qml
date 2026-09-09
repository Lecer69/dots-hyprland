import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.settings.data

PanelWindow {
    id: root

    property string icon: ""
    property string label: ""
    property bool showing: false

    readonly property string barPosition: SettingsData.s.bar.position

    anchors.top: barPosition === "top"
    anchors.bottom: barPosition === "bottom"
    anchors.left: barPosition === "left"
    anchors.right: barPosition === "right"

    WlrLayershell.margins.top: barPosition === "top" ? 15 : 0
    WlrLayershell.margins.bottom: barPosition === "bottom" ? 15 : 0
    WlrLayershell.margins.left: barPosition === "left" ? 15 : 0
    WlrLayershell.margins.right: barPosition === "right" ? 15 : 0

    implicitWidth: 110
    implicitHeight: 40
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    visible: showing

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