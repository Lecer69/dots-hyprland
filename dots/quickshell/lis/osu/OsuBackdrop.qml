import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.settings.data

Variants {
    id: root

    model: Quickshell.screens

    property string focusedAppId: ToplevelManager.activeToplevel?.appId ?? ""
    // neki.exe is another osu! client
    readonly property bool osuFocused: ["osu!", "osu.exe", "neki.exe"].some(n => focusedAppId.toLowerCase().includes(n))
    readonly property bool enabled: SettingsData.s.osu.backdropOtherMonitors && osuFocused

    delegate: PanelWindow {
        id: backdropWindow

        required property var modelData
        readonly property string focusedMonitorName: Hyprland.focusedMonitor?.name ?? ""
        readonly property bool isFocusedScreen: modelData.name === focusedMonitorName
        readonly property bool shown: root.enabled && !isFocusedScreen

        screen: modelData
        // Stays mapped until it has faded out
        visible: shown || dim.opacity > 0

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
            id: dim

            anchors.fill: parent
            color: SettingsData.s.osu.backdropColor
            opacity: backdropWindow.shown ? SettingsData.s.osu.backdropOpacity : 0

            Behavior on opacity {
                NumberAnimation {
                    duration: SettingsData.s.osu.backdropFadeDuration
                    easing.type: Easing.InOutQuad
                }
            }
        }
    }
}
