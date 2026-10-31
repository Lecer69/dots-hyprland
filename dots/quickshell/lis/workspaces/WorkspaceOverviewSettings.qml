pragma Singleton

import QtQuick
import Quickshell
import qs.settings.data
import qs.common

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

    property color activeBorderColor: Theme.text
    property color backgroundColor: Theme.panel
    property color backgroundBorderColor: Theme.border
    property color workspaceColor: Theme.hover
    property color workspaceHoverColor: Theme.border
    property color workspaceHoverBorderColor: Theme.adapt("#2a2a2a")
    property color windowOverlayColor: Theme.adapt("#330f0f0f")
    property color windowOverlayHoverColor: Theme.adapt("#4a1c1c1c")
    property color windowOverlayPressColor: Theme.adapt("#803a3a3a")
    property color windowBorderColor: Theme.adapt("#1d2a2a2a")
    property color workspaceNumberColor: Theme.adapt("#33656565")

    property real largeWorkspaceRadius: 4
    property real smallWorkspaceRadius: 4
    property real windowMinRadius: 6

    property int elevationMargin: 10
    property real backgroundPadding: 8
    property real workspaceSpacing: 5
}