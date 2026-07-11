import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool shown: false
    property var player: null
    property Item anchorItem: null
    signal closeRequested()

    visible: shown
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:media"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.closeRequested()
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.closeRequested()
    }

    property real lockedX: 0
    property real lockedY: 0

    onShownChanged: {
        if (shown && anchorItem && root.screen) {
            const pos = anchorItem.mapToGlobal(0, 0)
            const screenX = pos.x - root.screen.x
            const screenY = pos.y - root.screen.y
            const sw = root.screen.width
            const sh = root.screen.height
            const centeredX = screenX + (anchorItem.width / 2) - (340 / 2)
            lockedX = Math.max(8, Math.min(sw - 340 - 8, centeredX + 12))
            lockedY = Math.max(8, Math.min(sh - 160 - 8, screenY + anchorItem.height + 12))
        }
    }

    MediaPanel {
        id: panel
        width: 340
        height: 160
        player: root.player
        shown: root.shown

        x: root.lockedX
        y: root.lockedY

        onCloseRequested: root.closeRequested()
    }
}
