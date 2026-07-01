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

    property int arbitraryRaceConditionDelay: 60

    property int livePreviewMaxWidth: 480
    property int livePreviewMaxHeight: 270

    property color activeBorderColor: SettingsData.s.general.accentColor
    property color backgroundColor: "#0f0f0f"
    property color workspaceColor: "#141414"
    property color workspaceHoverColor: "#1c1c1c"
    property color workspaceHoverBorderColor: "#2a2a2a"
    property color windowOverlayColor: "#330f0f0f"
    property color windowOverlayHoverColor: "#4a1c1c1c"
    property color windowOverlayPressColor: "#803a3a3a"
    property color windowBorderColor: "#1d2a2a2a"
    property color workspaceNumberColor: '#33656565'

    property real largeWorkspaceRadius: 24
    property real smallWorkspaceRadius: 8
    property real windowMinRadius: 6

    property int elevationMargin: 10
    property real backgroundPadding: 10
    property real workspaceSpacing: 5
}