import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.settings.components
import qs.settings.data
import qs.settings.pages

PanelWindow {
    id: settingsWindow

    property bool shown: false

    visible: shown
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: settingsWindow.shown = false
    }

    SettingsPanel {
        anchors.centerIn: parent
        width: 780
        height: 560
        onCloseRequested: settingsWindow.shown = false

        layer.enabled: true
        layer.effect: null
    }

    GlobalShortcut {
        name: "settings"
        description: "Opens settings"
        onPressed: settingsWindow.shown = !settingsWindow.shown
    }
}
