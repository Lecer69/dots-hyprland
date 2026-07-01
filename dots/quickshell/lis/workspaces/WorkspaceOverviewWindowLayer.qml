pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.tools

Item {
    id: root

    required property var monitor
    required property var monitorData
    required property var windowByAddress
    required property real workspaceGroup
    required property real workspacesShown
    required property real workspaceImplicitWidth
    required property real workspaceImplicitHeight
    required property real largeWorkspaceRadius
    required property real smallWorkspaceRadius
    required property real workspaceSpacing
    required property real scale
    required property color activeBorderColor

    required property var getWsRow
    required property var getWsColumn

    property int draggingFromWorkspace: -1
    required property int draggingTargetWorkspace

    readonly property int workspaceZ: 0
    readonly property int windowZ: 1
    readonly property int windowDraggingZ: 99999

    Repeater {
        model: ScriptModel {
            values: {
                return ToplevelManager.toplevels.values.filter((toplevel) => {
                    const address = `0x${toplevel.HyprlandToplevel?.address}`
                    var win = root.windowByAddress[address]
                    const inWorkspaceGroup = (root.workspaceGroup * root.workspacesShown < win?.workspace?.id && win?.workspace?.id <= (root.workspaceGroup + 1) * root.workspacesShown)
                    return inWorkspaceGroup;
                })
            }
        }
        delegate: WorkspaceOverviewWindowTile {
            id: window
            required property var modelData
            property int monitorId: windowData?.monitor
            property var monitor: HyprlandData.monitors.find(m => m.id == monitorId)
            property var address: `0x${modelData.HyprlandToplevel.address}`
            toplevel: modelData
            monitorData: this.monitor
            scale: root.scale
            widgetMonitor: HyprlandData.monitors.find(m => m.id == root.monitor?.id) ?? null
            windowData: root.windowByAddress[address]
            isOnActiveWorkspace: windowData?.workspace?.id === (root.monitor?.activeWorkspace?.id ?? -1)

            property bool atInitPosition: (initX == x && initY == y)

            property int workspaceColIndex: root.getWsColumn(windowData?.workspace?.id ?? 1)
            property int workspaceRowIndex: root.getWsRow(windowData?.workspace?.id ?? 1)
            xOffset: (root.workspaceImplicitWidth + root.workspaceSpacing) * workspaceColIndex
            yOffset: (root.workspaceImplicitHeight + root.workspaceSpacing) * workspaceRowIndex
            property real xWithinWorkspaceWidget: Math.max((windowData?.at[0] - (monitor?.x ?? 0) - monitorData?.reserved[0]) * root.scale, 0)
            property real yWithinWorkspaceWidget: Math.max((windowData?.at[1] - (monitor?.y ?? 0) - monitorData?.reserved[1]) * root.scale, 0)

            property real minRadius: WorkspaceOverviewSettings.windowMinRadius
            property bool workspaceAtLeft: workspaceColIndex === 0
            property bool workspaceAtRight: workspaceColIndex === WorkspaceOverviewSettings.columns - 1
            property bool workspaceAtTop: workspaceRowIndex === 0
            property bool workspaceAtBottom: workspaceRowIndex === WorkspaceOverviewSettings.rows - 1
            property bool workspaceAtTopLeft: (workspaceAtLeft && workspaceAtTop)
            property bool workspaceAtTopRight: (workspaceAtRight && workspaceAtTop)
            property bool workspaceAtBottomLeft: (workspaceAtLeft && workspaceAtBottom)
            property bool workspaceAtBottomRight: (workspaceAtRight && workspaceAtBottom)
            property real distanceFromLeftEdge: xWithinWorkspaceWidget
            property real distanceFromRightEdge: root.workspaceImplicitWidth - (xWithinWorkspaceWidget + targetWindowWidth)
            property real distanceFromTopEdge: yWithinWorkspaceWidget
            property real distanceFromBottomEdge: root.workspaceImplicitHeight - (yWithinWorkspaceWidget + targetWindowHeight)
            property real distanceFromTopLeftCorner: Math.max(distanceFromLeftEdge, distanceFromTopEdge)
            property real distanceFromTopRightCorner: Math.max(distanceFromRightEdge, distanceFromTopEdge)
            property real distanceFromBottomLeftCorner: Math.max(distanceFromLeftEdge, distanceFromBottomEdge)
            property real distanceFromBottomRightCorner: Math.max(distanceFromRightEdge, distanceFromBottomEdge)
            topLeftRadius: Math.max((workspaceAtTopLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopLeftCorner, minRadius)
            topRightRadius: Math.max((workspaceAtTopRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromTopRightCorner, minRadius)
            bottomLeftRadius: Math.max((workspaceAtBottomLeft ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomLeftCorner, minRadius)
            bottomRightRadius: Math.max((workspaceAtBottomRight ? root.largeWorkspaceRadius : root.smallWorkspaceRadius) - distanceFromBottomRightCorner, minRadius)

            Timer {
                id: updateWindowPosition
                interval: WorkspaceOverviewSettings.arbitraryRaceConditionDelay
                repeat: false
                running: false
                onTriggered: {
                    window.x = Math.round(xWithinWorkspaceWidget + xOffset)
                    window.y = Math.round(yWithinWorkspaceWidget + yOffset)
                }
            }

            z: Drag.active ? root.windowDraggingZ : (root.windowZ + windowData?.floating)
            Drag.hotSpot.x: width / 2
            Drag.hotSpot.y: height / 2
            MouseArea {
                id: dragArea
                anchors.fill: parent
                hoverEnabled: true
                onEntered: hovered = true
                onExited: hovered = false
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                drag.target: parent
                onPressed: (mouse) => {
                    root.draggingFromWorkspace = windowData?.workspace.id
                    window.pressed = true
                    window.Drag.active = true
                    window.Drag.source = window
                    window.Drag.hotSpot.x = mouse.x
                    window.Drag.hotSpot.y = mouse.y
                }
                onReleased: {
                    const targetWorkspace = root.draggingTargetWorkspace
                    window.pressed = false
                    window.Drag.active = false
                    root.draggingFromWorkspace = -1
                    if (targetWorkspace !== -1 && targetWorkspace !== windowData?.workspace.id) {
                        Hyprland.dispatch(`movetoworkspacesilent ${targetWorkspace}, address:${window.windowData?.address}`)
                        updateWindowPosition.restart()
                    }
                    else {
                        if (!window.windowData.floating) {
                            updateWindowPosition.restart()
                            return
                        }
                        const percentageX = Math.round((window.x - xOffset) / root.workspaceImplicitWidth * 100)
                        const percentageY = Math.round((window.y - yOffset) / root.workspaceImplicitHeight * 100)
                        Hyprland.dispatch(`movewindowpixel exact ${percentageX}% ${percentageY}%, address:${window.windowData?.address}`)
                    }
                }
                onClicked: (event) => {
                    if (!windowData) return;

                    if (event.button === Qt.LeftButton) {
                        WorkspaceOverviewState.overviewOpen = false
                        Hyprland.dispatch(`focuswindow address:${windowData.address}`)
                        event.accepted = true
                    } else if (event.button === Qt.MiddleButton) {
                        Hyprland.dispatch(`closewindow address:${windowData.address}`)
                        event.accepted = true
                    }
                }

                ToolTip {
                    id: windowTooltip
                    visible: dragArea.containsMouse && !window.Drag.active
                    delay: 400
                    text: `${windowData?.title}\n[${windowData?.class}] ${windowData?.xwayland ? "[XWayland] " : ""}`
                }
            }
        }
    }

    // Focused workspace indicator
    Rectangle {
        id: focusedWorkspaceIndicator
        property int rowIndex: root.monitor ? root.getWsRow(root.monitor.activeWorkspace?.id ?? 1) : 0
        property int colIndex: root.monitor ? root.getWsColumn(root.monitor.activeWorkspace?.id ?? 1) : 0
        x: (root.workspaceImplicitWidth + root.workspaceSpacing) * colIndex
        y: (root.workspaceImplicitHeight + root.workspaceSpacing) * rowIndex
        z: root.windowZ
        width: root.workspaceImplicitWidth
        height: root.workspaceImplicitHeight
        color: "transparent"
        property bool workspaceAtLeft: colIndex === 0
        property bool workspaceAtRight: colIndex === WorkspaceOverviewSettings.columns - 1
        property bool workspaceAtTop: rowIndex === 0
        property bool workspaceAtBottom: rowIndex === WorkspaceOverviewSettings.rows - 1
        topLeftRadius: (workspaceAtLeft && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
        topRightRadius: (workspaceAtRight && workspaceAtTop) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
        bottomLeftRadius: (workspaceAtLeft && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
        bottomRightRadius: (workspaceAtRight && workspaceAtBottom) ? root.largeWorkspaceRadius : root.smallWorkspaceRadius
        border.width: 2
        border.color: root.activeBorderColor
        Behavior on x {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on y {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on topLeftRadius {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on topRightRadius {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on bottomLeftRadius {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
        Behavior on bottomRightRadius {
            NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
        }
    }
}