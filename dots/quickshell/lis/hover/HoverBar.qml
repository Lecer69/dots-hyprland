import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.settings.data

PanelWindow {
    id: root

    // Which screen side this strip sits on for horizontal bars
    property bool preferredRight: false
    // Which end of the bar edge this strip sits on for vertical bars
    property bool bottomEnd: false

    readonly property string barPosition: SettingsData.s.bar.position
    readonly property bool verticalBar: barPosition === "left" || barPosition === "right"

    readonly property bool anchorTop: barPosition === "top" || (verticalBar && !bottomEnd)
    readonly property bool anchorBottom: barPosition === "bottom" || (verticalBar && bottomEnd)
    readonly property bool anchorLeft: barPosition === "left" || (!verticalBar && !preferredRight)
    readonly property bool anchorRight: barPosition === "right" || (!verticalBar && preferredRight)

    WlrLayershell.layer: WlrLayer.Overlay
    implicitWidth: verticalBar ? 40 : 15
    implicitHeight: verticalBar ? 15 : 40
    color: "transparent"
    exclusiveZone: 0

    // Stick out of the screen edge so only a thin sliver is hoverable
    WlrLayershell.margins.top: anchorTop && !verticalBar ? -33 : 0
    WlrLayershell.margins.bottom: anchorBottom && !verticalBar ? -33 : 0
    WlrLayershell.margins.left: anchorLeft && verticalBar ? -33 : 0
    WlrLayershell.margins.right: anchorRight && verticalBar ? -33 : 0

    anchors.top: anchorTop
    anchors.bottom: anchorBottom
    anchors.left: anchorLeft
    anchors.right: anchorRight

    property real value: 0
    signal scrolled(real delta)

    property bool hovered: false
    property var hyprMonitor: Hyprland.monitorFor(root.screen)
    property bool fullscreen: hyprMonitor?.activeWorkspace?.hasFullscreen ?? false

    Rectangle {
        id: strip

        width: root.verticalBar ? 30 : 4
        height: root.verticalBar ? 4 : 30

        // Horizontal bars: hug the top/bottom edge. Vertical bars: hug the left/right edge
        x: root.verticalBar
            ? (root.anchorLeft ? 8 : root.width - width - 8)
            : (root.anchorRight ? root.width - width - 3.5 : 3.5)
        y: root.verticalBar
            ? (root.height - height) / 2
            : (root.anchorTop ? 8 : root.height - height - 8)

        radius: 5
        color: "#22ffffff"
        visible: !fullscreen
        opacity: root.hovered ? 1.0 : 0.0
        clip: true

        Behavior on opacity { NumberAnimation { duration: 180 } }

        // Horizontal bars: fill grows bottom-up. Vertical bars: left-to-right
        Rectangle {
            anchors.bottom: root.verticalBar ? undefined : parent.bottom
            anchors.left: root.verticalBar ? parent.left : undefined
            radius: parent.radius
            width: root.verticalBar ? parent.width * root.value : parent.width
            height: root.verticalBar ? parent.height : parent.height * root.value
            color: '#ffffff'
            Behavior on width { NumberAnimation { duration: 80 } }
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