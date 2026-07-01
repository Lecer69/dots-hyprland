import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root
    WlrLayershell.margins.top: -33
    WlrLayershell.margins.right: 0
    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: 15
    implicitHeight: 40
    color: "transparent"
    exclusiveZone: 0
    anchors.top: true

    property real value: 0
    signal scrolled(real delta)

    property bool hovered: false
    property var hyprMonitor: Hyprland.monitorFor(root.screen)
    property bool fullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    Rectangle {
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.right: root.anchors.right ? parent.right : undefined
        anchors.left: root.anchors.left ? parent.left : undefined
        anchors.rightMargin: 3.5
        anchors.leftMargin: 3.5
        width: 4
        height: 30
        radius: 5
        color: "#22ffffff"
        visible: !fullscreen
        opacity: root.hovered ? 1.0 : 0.0
        clip: true

        Behavior on opacity { NumberAnimation { duration: 180 } }

        Rectangle {
            anchors.bottom: parent.bottom
            radius: parent.radius
            width: parent.width
            height: parent.height * root.value
            color: '#ffffff'
            Behavior on height { NumberAnimation { duration: 80 } }
        }
    }

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered = true
        onExited: root.hovered = false
        onWheel: wh => {
            if (root.fullscreen) return
            const delta = wh.angleDelta.y > 0 ? 0.02 : -0.02
            root.scrolled(delta)
        }
    }
}