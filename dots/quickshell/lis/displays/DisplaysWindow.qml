import qs.common

PanelHost {
    id: root

    name: "displays"
    description: "Toggles the display settings"
    // While the file chooser is open
    hidden: root.item?.picking ?? false

    // Stays open while the new settings wait to be kept; while picking, opening it again closes the chooser
    toggle: () => {
        if (root.item?.picking) root.item.cancelPick()
        else if (!root.item?.confirming) root.shown = !root.shown
    }
    open: () => {
        root.item?.cancelPick()
        root.shown = true
    }
    close: () => {
        root.item?.cancelPick()
        if (!root.item?.confirming) root.shown = false
    }

    DisplaysPanel {
        anchors.centerIn: parent
        width: 736
        height: Math.min(implicitHeight, parent.height - 80)
        shown: root.panelShown
        onCloseRequested: root.close()
    }
}
