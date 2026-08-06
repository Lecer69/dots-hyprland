pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Hyprland
import qs.tools

Column {
    id: root

    required property real workspaceGroup
    required property real workspacesShown
    required property real workspaceImplicitWidth
    required property real workspaceImplicitHeight
    required property real largeWorkspaceRadius
    required property real smallWorkspaceRadius
    required property real workspaceSpacing
    required property real scale
    required property real workspaceNumberSize

    required property int draggingFromWorkspace
    property int draggingTargetWorkspace: -1

    spacing: workspaceSpacing

    function getWsRow(ws) {
        var normalRow = Math.floor((ws - 1) / WorkspaceOverviewSettings.columns) % WorkspaceOverviewSettings.rows;
        return (WorkspaceOverviewSettings.orderBottomUp ? WorkspaceOverviewSettings.rows - normalRow - 1 : normalRow);
    }
    function getWsColumn(ws) {
        var normalCol = (ws - 1) % WorkspaceOverviewSettings.columns;
        return (WorkspaceOverviewSettings.orderRightLeft ? WorkspaceOverviewSettings.columns - normalCol - 1 : normalCol);
    }
    function getWsInCell(ri, ci) {
        return (WorkspaceOverviewSettings.orderBottomUp ? WorkspaceOverviewSettings.rows - ri - 1 : ri) * WorkspaceOverviewSettings.columns + (WorkspaceOverviewSettings.orderRightLeft ? WorkspaceOverviewSettings.columns - ci - 1 : ci) + 1
    }

    Repeater {
        model: WorkspaceOverviewSettings.rows
        delegate: Row {
            id: gridRow
            required property int index
            spacing: root.workspaceSpacing

            Repeater {
                model: WorkspaceOverviewSettings.columns

                // Workspace cell
                Rectangle {
                    id: workspace

                    required property int index
                    property int colIndex: index

                    property int workspaceValue: root.workspaceGroup * root.workspacesShown + root.getWsInCell(gridRow.index, colIndex)
                    property color defaultWorkspaceColor: WorkspaceOverviewSettings.workspaceColor
                    property color hoveredWorkspaceColor: WorkspaceOverviewSettings.workspaceHoverColor
                    property color hoveredBorderColor: WorkspaceOverviewSettings.workspaceHoverBorderColor
                    property bool hoveredWhileDragging: false

                    implicitWidth: root.workspaceImplicitWidth
                    implicitHeight: root.workspaceImplicitHeight
                    color: hoveredWhileDragging ? hoveredWorkspaceColor : defaultWorkspaceColor

                    property bool workspaceAtLeft: colIndex === 0
                    property bool workspaceAtRight: colIndex === WorkspaceOverviewSettings.columns - 1
                    property bool workspaceAtTop: gridRow.index === 0
                    property bool workspaceAtBottom: gridRow.index === WorkspaceOverviewSettings.rows - 1

                    topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
                    bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius

                    border.width: 2
                    border.color: hoveredWhileDragging ? hoveredBorderColor : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: workspace.workspaceValue
                        font {
                            pixelSize: root.workspaceNumberSize * root.scale
                            weight: Font.DemiBold
                        }
                        color: WorkspaceOverviewSettings.workspaceNumberColor
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }

                    MouseArea {
                        id: workspaceArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        onPressed: {
                            if (root.draggingTargetWorkspace === -1) {
                                WorkspaceOverviewState.overviewOpen = false
                                Hyprland.dispatch(`hl.dsp.focus({ workspace = "${workspace.workspaceValue}" })`)
                            }
                        }
                    }

                    DropArea {
                        anchors.fill: parent
                        onEntered: {
                            root.draggingTargetWorkspace = workspace.workspaceValue
                            if (root.draggingFromWorkspace == root.draggingTargetWorkspace) return;
                            hoveredWhileDragging = true
                        }
                        onExited: {
                            hoveredWhileDragging = false
                            if (root.draggingTargetWorkspace == workspace.workspaceValue) root.draggingTargetWorkspace = -1
                        }
                    }
                }
            }
        }
    }
}