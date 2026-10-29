pragma Singleton

import QtQuick
import Quickshell
import qs.settings.data

Singleton {
    id: root

    property int rows: SettingsData.s.workspaceOverview.rows
    property int columns: SettingsData.s.workspaceOverview.columns
    property real scale: SettingsData.s.workspaceOverview.scale
    property bool orderBottomUp: SettingsData.s.workspaceOverview.orderBottomUp
    property bool orderRightLeft: SettingsData.s.workspaceOverview.orderRightLeft
    property bool centerIcons: SettingsData.s.workspaceOverview.centerIcons

    property int livePreviewMaxWidth: 480
    property int livePreviewMaxHeight: 270

    property color activeBorderColor: "#e6e6e6"
    property color backgroundColor: "#0f0f0f"
    property color backgroundBorderColor: "#1f1f1f"
    property color workspaceColor: "#161616"
    property color workspaceHoverColor: "#1f1f1f"
    property color workspaceHoverBorderColor: "#2a2a2a"
    property color windowOverlayColor: "#330f0f0f"
    property color windowOverlayHoverColor: "#4a1c1c1c"
    property color windowOverlayPressColor: "#803a3a3a"
    property color windowBorderColor: "#1d2a2a2a"
    property color workspaceNumberColor: '#33656565'

    property real largeWorkspaceRadius: 4
    property real smallWorkspaceRadius: 4
    property real windowMinRadius: 6

    property int elevationMargin: 10
    property real backgroundPadding: 8
    property real workspaceSpacing: 5
}