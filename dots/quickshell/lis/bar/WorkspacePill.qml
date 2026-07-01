import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Widgets
import qs.tools

Item {
    id: root

    property int wsIndex: 0
    property bool focused: false
    property bool occupied: false

    property var monitor: Hyprland.monitorFor(bar.screen)
    property var ws: Hyprland.workspaces.values.find(w => w.id === root.wsIndex)
    property var biggestWindow: HyprlandData.biggestWindowForWorkspace(root.wsIndex)

    property bool focusedOnOtherMonitor: {
        for (const m of Hyprland.monitors.values) {
            if (m === monitor) continue
            if (m.activeWorkspace?.id === root.wsIndex) return true
        }
        return false
    }

    property string iconSource: {
        const win = biggestWindow
        if (!win || !win.class) return ""

        const icon = AppSearch.guessIcon(win.class)
        return icon ? Quickshell.iconPath(icon, "image-missing") : ""
    }

    property bool sameMonitor: {
        const wsObj = HyprlandData.workspaceById?.[root.wsIndex]
        if (!wsObj) return true

        return wsObj.monitor === monitor?.name
    }

    width: 22
    height: 22

    // Focused circle
    Rectangle {
        anchors.fill: parent
        radius: 12
        color: (focused || focusedOnOtherMonitor)
            ? (root.iconSource === "" ? '#beffffff' : '#43ffffff')
            : "#00000000"

        opacity: focused ? 1.0 : focusedOnOtherMonitor ? 0.4 : 1.0
        Behavior on color { ColorAnimation  { duration: 160 } }
        Behavior on opacity { NumberAnimation { duration: 160 } }
    }

    // Workspace number
    Text {
        id: wsNum
        anchors.centerIn: parent
        text: root.wsIndex
        visible: root.iconSource === ""
        font.pixelSize: 14
        font.weight: Font.Medium
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        color: focused ? "#111111" : '#969696'
        Behavior on color { ColorAnimation { duration: 160 } }
    }

    // App icon
    Image {
        anchors.centerIn: parent
        width: 18
        height: 18
        source: root.iconSource
        fillMode: Image.PreserveAspectFit
        opacity: sameMonitor ? 1.0 : 0.38
        visible: root.iconSource !== ""
        smooth: true
        mipmap: true
        antialiasing: true
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: HyprlandData.dispatchWorkspace(root.wsIndex)
        hoverEnabled: true
        onEntered: hoverRect.visible = true
        onExited:  hoverRect.visible = false
    }

    Rectangle {
        id: hoverRect
        anchors.fill: parent
        radius: 11
        color: "#ffffff"
        opacity: 0.05
        visible: false
    }
}