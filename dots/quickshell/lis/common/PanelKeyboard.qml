import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

// Keyboard focus for panel windows: exclusive while open and on top (Hyprland 0.57 doesn't focus on-demand layers)
Item {
    id: root

    property bool open: false
    property Item initialFocus: null
    readonly property string screenName: QsWindow.window?.screen?.name ?? ""
    readonly property bool onFocusedScreen: {
        const focused = Hyprland.focusedMonitor
        return root.screenName === "" || !focused || focused.name === root.screenName
    }
    // On-demand while the pointer is on another screen, so the keyboard follows it there
    readonly property int mode: !root.open || PanelFocus.topOn(root.screenName) !== root ? WlrKeyboardFocus.None
        : root.onFocusedScreen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.OnDemand
    readonly property Item focusedItem: Window.activeFocusItem

    // Scrolls the nearest Flickable to show `item`; taller items are left alone
    function scrollIntoView(item: Item): void {
        let flick = item.parent
        for (let i = 0; flick && flick.flickableDirection === undefined && i < 100; i++)
            flick = flick.parent
        if (!flick || flick.flickableDirection === undefined || item.height > flick.height) return

        const margin = 8
        const y = item.mapToItem(flick.contentItem, 0, 0).y
        const minY = flick.originY
        const maxY = Math.max(minY, flick.originY + flick.contentHeight - flick.height)
        if (y - margin < flick.contentY)
            flick.contentY = Math.max(minY, y - margin)
        else if (y + item.height + margin > flick.contentY + flick.height)
            flick.contentY = Math.min(maxY, y + item.height + margin - flick.height)
    }

    onOpenChanged: {
        if (root.open) {
            PanelFocus.opened(root)
            ;(root.initialFocus ?? root).forceActiveFocus()
        } else {
            PanelFocus.closed(root)
        }
    }
    onFocusedItemChanged: if (root.focusedItem) root.scrollIntoView(root.focusedItem)
    Component.onCompleted: if (root.open) PanelFocus.opened(root)
    Component.onDestruction: PanelFocus.closed(root)
}
