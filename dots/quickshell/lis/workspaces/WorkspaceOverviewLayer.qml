import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import QtQuick

PanelWindow {
    id: overviewWin

    readonly property var focusedScreen: {
        const monitorName = Hyprland.focusedMonitor?.name
        return Quickshell.screens.find(s => s.name === monitorName) ?? null
    }

    screen: focusedScreen
    visible: WorkspaceOverviewState.overviewOpen && focusedScreen !== null

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"

    Keys.onEscapePressed: WorkspaceOverviewState.overviewOpen = false

    MouseArea {
        anchors.fill: parent
        onClicked: WorkspaceOverviewState.overviewOpen = false

        Loader {
            anchors.centerIn: parent
            active: WorkspaceOverviewState.overviewOpen && overviewWin.focusedScreen !== null
            sourceComponent: WorkspaceOverview {
                screen: overviewWin.focusedScreen
                MouseArea {
                    anchors.fill: parent
                    onClicked: mouse => mouse.accepted = false
                    onPressed: mouse => mouse.accepted = false
                }
            }
        }
    }
}