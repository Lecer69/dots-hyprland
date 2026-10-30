import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.settings.data
import qs.tools

PanelWindow {
    id: root

    // Screen side, for horizontal bars
    property bool preferredRight: false
    // Edge end, for vertical bars
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

    // Sticks out of the screen so only a sliver is hoverable
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
    signal clicked()

    property bool hovered: false
    // Wheel travel not yet a step (120 = one notch)
    property int wheelAccum: 0
    property var hyprMonitor: Hyprland.monitorFor(root.screen)
    // hasFullscreen counts maximized windows too
    property bool fullscreen: HyprlandData.hasFullscreen(hyprMonitor?.activeWorkspace?.id ?? -1)

    Rectangle {
        id: strip

        width: root.verticalBar ? 30 : 4
        height: root.verticalBar ? 4 : 30

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

        // Fills bottom-up, or left-to-right on vertical bars
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
        onClicked: if (!root.fullscreen) root.clicked()
        onWheel: wh => {
            if (root.fullscreen) return
            // Touchpads send many tiny deltas, so step per notch's worth of travel
            if (wh.phase === Qt.ScrollEnd) {
                root.wheelAccum = 0
                return
            }
            root.wheelAccum += wh.angleDelta.y
            const steps = Math.trunc(root.wheelAccum / 120)
            if (steps === 0) return
            root.wheelAccum -= steps * 120
            root.scrolled(steps * 0.02)
        }
    }
}