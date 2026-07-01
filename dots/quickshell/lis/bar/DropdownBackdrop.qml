import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property var activeMenu: null

    visible: false
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors.top: true
    anchors.bottom: true
    anchors.left: true
    anchors.right: true

    exclusionMode: ExclusionMode.Ignore

    function open(menu) {
        if (activeMenu && activeMenu !== menu)
            activeMenu.visible = false

        activeMenu = menu
        visible = true
        catchArea.forceActiveFocus()
    }

    function close() {
        if (activeMenu) {
            activeMenu.visible = false
            activeMenu = null
        }
        visible = false
    }

    onVisibleChanged: if (visible) catchArea.forceActiveFocus()

    MouseArea {
        id: catchArea
        anchors.fill: parent
        focus: true
        onClicked: root.close()
        Keys.onPressed: (event) => {
            root.close()
            event.accepted = true
        }
    }
}
