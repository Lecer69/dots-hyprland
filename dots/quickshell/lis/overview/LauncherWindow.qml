import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: win

    property bool isOpen: false
    property string initialQuery: ""

    signal closeRequested()

    visible: isOpen
    color: "transparent"

    WlrLayershell.namespace: "quickshell:launcher"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: isOpen ? launcherCard : null
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: win.closeRequested()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (!win.isOpen) return

            if (event.name === "workspace" || event.name === "activewindow" || event.name === "focusedmon" || event.name === "activespecial")
                win.closeRequested()
        }
    }

    LauncherCard {
        id: launcherCard
        isOpen: win.isOpen
        initialQuery: win.initialQuery

        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 80

        onCloseRequested: win.closeRequested()
    }
}
