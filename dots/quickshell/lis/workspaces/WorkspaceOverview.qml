pragma ComponentBehavior: Bound

import Qt5Compat.GraphicalEffects
import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.tools

Item {
    id: root
    required property var screen
    readonly property HyprlandMonitor monitor: Hyprland.monitorFor(screen)
    readonly property int workspacesShown: WorkspaceOverviewSettings.rows * WorkspaceOverviewSettings.columns
    readonly property int workspaceGroup: monitor
        ? Math.floor(((monitor.activeWorkspace?.id ?? 1) - 1) / workspacesShown)
        : 0
    property bool monitorIsFocused: monitor ? (Hyprland.focusedMonitor?.name === monitor.name) : false
    property var windowByAddress: HyprlandData.windowByAddress
    property var monitorData: HyprlandData.monitors.find(m => m.id === root.monitor?.id)
    property real scale: WorkspaceOverviewSettings.scale
    property color activeBorderColor: WorkspaceOverviewSettings.activeBorderColor

    property real workspaceImplicitWidth: {
        if (!monitorData || !monitor) return 0
        return (monitorData.transform % 2 === 1)
            ? ((monitor.height - monitorData.reserved[0] - monitorData.reserved[2]) * root.scale / monitor.scale)
            : ((monitor.width  - monitorData.reserved[0] - monitorData.reserved[2]) * root.scale / monitor.scale)
    }
    property real workspaceImplicitHeight: {
        if (!monitorData || !monitor) return 0
        return (monitorData.transform % 2 === 1)
            ? ((monitor.width  - monitorData.reserved[1] - monitorData.reserved[3]) * root.scale / monitor.scale)
            : ((monitor.height - monitorData.reserved[1] - monitorData.reserved[3]) * root.scale / monitor.scale)
    }
    property real largeWorkspaceRadius: WorkspaceOverviewSettings.largeWorkspaceRadius
    property real smallWorkspaceRadius: WorkspaceOverviewSettings.smallWorkspaceRadius

    property real workspaceNumberMargin: 80
    property real workspaceNumberSize: 250 * (monitor?.scale ?? 1)
    property real workspaceSpacing: WorkspaceOverviewSettings.workspaceSpacing

    implicitWidth: overviewBackground.implicitWidth + WorkspaceOverviewSettings.elevationMargin * 2
    implicitHeight: overviewBackground.implicitHeight + WorkspaceOverviewSettings.elevationMargin * 2

    // Background
    Rectangle {
        id: overviewBackground
        property real padding: WorkspaceOverviewSettings.backgroundPadding
        anchors.fill: parent
        anchors.margins: WorkspaceOverviewSettings.elevationMargin

        implicitWidth: workspaceGrid.implicitWidth + padding * 2
        implicitHeight: workspaceGrid.implicitHeight + padding * 2
        radius: root.largeWorkspaceRadius + padding
        color: WorkspaceOverviewSettings.backgroundColor

        layer.enabled: true
        layer.effect: DropShadow {
            horizontalOffset: 0
            verticalOffset: 4
            radius: 24
            samples: 49
            color: "#80000000"
        }

        WorkspaceOverviewGrid {
            id: workspaceGrid
            anchors.centerIn: parent
            workspaceGroup: root.workspaceGroup
            workspacesShown: root.workspacesShown
            workspaceImplicitWidth: root.workspaceImplicitWidth
            workspaceImplicitHeight: root.workspaceImplicitHeight
            largeWorkspaceRadius: root.largeWorkspaceRadius
            smallWorkspaceRadius: root.smallWorkspaceRadius
            workspaceSpacing: root.workspaceSpacing
            scale: root.scale
            workspaceNumberSize: root.workspaceNumberSize

            draggingFromWorkspace: windowLayer.draggingFromWorkspace
        }

        WorkspaceOverviewWindowLayer {
            id: windowLayer
            anchors.centerIn: parent
            width: workspaceGrid.implicitWidth
            height: workspaceGrid.implicitHeight

            monitor: root.monitor
            monitorData: root.monitorData
            windowByAddress: root.windowByAddress
            workspaceGroup: root.workspaceGroup
            workspacesShown: root.workspacesShown
            workspaceImplicitWidth: root.workspaceImplicitWidth
            workspaceImplicitHeight: root.workspaceImplicitHeight
            largeWorkspaceRadius: root.largeWorkspaceRadius
            smallWorkspaceRadius: root.smallWorkspaceRadius
            workspaceSpacing: root.workspaceSpacing
            scale: root.scale
            activeBorderColor: root.activeBorderColor

            getWsRow: workspaceGrid.getWsRow
            getWsColumn: workspaceGrid.getWsColumn

            draggingTargetWorkspace: workspaceGrid.draggingTargetWorkspace
        }
    }
}