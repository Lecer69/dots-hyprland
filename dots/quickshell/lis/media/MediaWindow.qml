import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property bool shown: false
    property var player: null
    property Item anchorItem: null
    signal closeRequested()

    // Stay visible while the panel fades out
    visible: shown || panel.opacity > 0.01
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

    function updateAnchor(): void {
        if (!shown || !anchorItem || !root.screen) return
        const pos = anchorItem.mapToGlobal(0, 0)
        const screenX = pos.x - root.screen.x
        const screenY = pos.y - root.screen.y
        const sw = root.screen.width
        const sh = root.screen.height
        const pw = panel.width
        const ph = panel.contentHeight
        const centeredX = screenX + (anchorItem.width / 2) - (pw / 2)
        lockedX = Math.max(8, Math.min(sw - pw - 8, centeredX + 12))
        lockedY = Math.max(8, Math.min(sh - ph - 8, screenY + anchorItem.height + 12))
    }

    onShownChanged: updateAnchor()

    MediaPanel {
        id: panel
        width: 360
        height: panel.contentHeight
        player: root.player
        shown: root.shown

        x: root.lockedX
        y: root.lockedY

        onCloseRequested: root.closeRequested()
    }
}