import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Widgets
import qs.settings.data
import qs.settings.pages
import qs.settings

ShellWindow {
    id: settingsWindow

    property bool shown: false

    anchors {
        horizontalCenter: true
        verticalCenter: true
    }

    width: 780
    height: 560
    visible: shown

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    color: "transparent"

    Shortcut {
        sequences: ["Escape"]
        onActivated: settingsWindow.shown = false
    }

    SettingsPanel {
        id: panel
        anchors.fill: parent
        onCloseRequested: settingsWindow.shown = false
    }
}
