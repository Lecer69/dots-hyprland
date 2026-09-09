import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property int menuWidth: 130
    property list<QtObject> items: []
    property var targetScreen: null
    property Item anchorItem: null

    screen: targetScreen ?? Quickshell.screens[0]

    property bool isOpen: false

    readonly property int itemHeight:  26
    readonly property int paddingV:    5
    readonly property int panelHeight: items.length * itemHeight + paddingV * 2 + (items.length - 1) * 2

    // Stay visible while the panel fades out
    visible: isOpen || panel.opacity > 0.01
    color: "transparent"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:dropdown"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.isOpen = false
    }

    // Click anywhere outside the panel closes the menu
    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.isOpen
        onClicked: root.isOpen = false
    }

    property real lockedX: 0
    property real lockedY: 0

    function openAt(item): void {
        if (!items || items.length === 0) return
        root.anchorItem = item
        root.isOpen = true
        updateAnchor()
    }

    // Place the panel next to the button that opened it, away from the bar.
    // The button always sits at a screen edge (it lives in the bar), so open
    // toward the opposite side and clamp on-screen.
    function updateAnchor(): void {
        if (!anchorItem || !root.screen) return
        const pos = anchorItem.mapToGlobal(0, 0)
        const bx = pos.x - root.screen.x
        const by = pos.y - root.screen.y
        const bw = anchorItem.width
        const bh = anchorItem.height
        const sw = root.screen.width
        const sh = root.screen.height
        const pw = panel.width
        const ph = root.panelHeight

        const cx = bx + bw / 2
        const cy = by + bh / 2
        const distLeft = bx
        const distTop = by
        const distRight = sw - (bx + bw)
        const distBottom = sh - (by + bh)

        let px, py
        if (distTop <= distLeft && distTop <= distRight && distTop <= distBottom) {
            py = by + bh + 6
            px = cx - pw / 2
        } else if (distBottom <= distLeft && distBottom <= distRight) {
            py = by - ph - 6
            px = cx - pw / 2
        } else if (distLeft <= distRight) {
            px = bx + bw + 6
            py = cy - ph / 2
        } else {
            px = bx - pw - 6
            py = cy - ph / 2
        }

        root.lockedX = Math.max(8, Math.min(sw - pw - 8, px))
        root.lockedY = Math.max(8, Math.min(sh - ph - 8, py))
    }

    Rectangle {
        id: panel

        opacity: root.isOpen ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        x: root.lockedX
        y: root.lockedY

        width:  root.menuWidth
        height: root.panelHeight

        radius: 10
        color:  "#e2121212"
        border.width: 1
        border.color: "#40ffffff"

        Column {
            id: itemColumn
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   root.paddingV
                leftMargin:  4
                rightMargin: 4
            }
            spacing: 2

            Repeater {
                model: root.items

                MenuItem {
                    width:  itemColumn.width
                    label:  modelData.label
                    icon:   modelData.icon
                    onTriggered: {
                        root.isOpen = false
                        modelData.action()
                    }
                }
            }
        }
    }
}