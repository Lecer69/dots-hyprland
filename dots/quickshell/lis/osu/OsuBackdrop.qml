import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.settings.data

Variants {
    id: root

    model: Quickshell.screens

    property string focusedAppId: ToplevelManager.activeToplevel?.appId ?? ""
    readonly property bool osuFocused: focusedAppId === "osu!.exe" || focusedAppId === "osu!"
    readonly property bool enabled: SettingsData.s.osu.backdropOtherMonitors && osuFocused

    delegate: PanelWindow {
        id: backdropWindow

        required property var modelData
        readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
        readonly property bool isFocusedScreen: modelData.name === focusedMonitorName

        screen: modelData
        visible: root.enabled && !isFocusedScreen

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.exclusiveZone: -1
        WlrLayershell.namespace: "quickshell:osubackdrop"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.None

        mask: Region {}

        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }

        Rectangle {
            anchors.fill: parent
            color: SettingsData.s.osu.backdropColor
            opacity: SettingsData.s.osu.backdropOpacity

            Behavior on opacity {
                NumberAnimation { duration: 1000 }
            }
        }
    }
}
