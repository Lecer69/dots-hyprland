import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

PanelWindow {
    id: root

    property bool isOpen: false
    property var targetScreen: null
    property var pendingAction: null

    // Stay visible while the buttons animate out
    visible: isOpen || buttonRow.opacity > 0.01
    color: "transparent"
    // Null (unset) means the primary screen; the bar button sets this
    // to its own screen on click, so the dialog opens where it was triggered
    screen: root.targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:power"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.isOpen = false
    }

    // Small delay so the close animation is visible before the action runs
    Timer {
        id: actionTimer
        interval: 300
        onTriggered: {
            if (root.pendingAction) {
                const action = root.pendingAction
                root.pendingAction = null
                action()
            }
        }
    }

    function run(action): void {
        root.pendingAction = action
        root.isOpen = false
        actionTimer.restart()
    }

    // Dim backdrop
    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: buttonRow.opacity * 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Just the buttons, centred
    Row {
        id: buttonRow

        anchors.centerIn: parent
        spacing: 36

        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1 : 0.95

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        PowerAction {
            index: 0
            label: "Shutdown"
            iconSource: "../icons/power.svg"
            accent: "#f38ba8"
            onActivated: root.run(() => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "shutdown"]))
        }

        PowerAction {
            index: 1
            label: "Reboot"
            iconSource: "../icons/restart.svg"
            accent: "#89b4fa"
            onActivated: root.run(() => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "reboot"]))
        }

        PowerAction {
            index: 2
            label: "Suspend"
            iconSource: "../icons/sleep.svg"
            accent: "#a6e3a1"
            onActivated: root.run(() => Quickshell.execDetached(["systemctl", "suspend"]))
        }

        PowerAction {
            index: 3
            label: "Exit"
            iconSource: "../icons/exit.svg"
            accent: "#f9e2af"
            onActivated: root.run(() => Hyprland.dispatch("exit"))
        }
    }

    component PowerAction: Item {
        id: action

        property string label: ""
        property string iconSource: ""
        property color accent: "#ffffff"
        property int index: 0
        signal activated()

        width: 128
        height: 128

        // Staggered entrance: fade + slide up, one button after another
        readonly property int enterDelay: root.isOpen ? action.index * 60 : 0

        opacity: root.isOpen ? 1 : 0

        property real enterY: root.isOpen ? 0 : 12
        transform: Translate { y: action.enterY }

        Behavior on opacity {
            SequentialAnimation {
                PauseAnimation { duration: action.enterDelay }
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }

        Behavior on enterY {
            SequentialAnimation {
                PauseAnimation { duration: action.enterDelay }
                NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
            }
        }

        scale: mouse.pressed ? 0.92 : 1
        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

        Rectangle {
            id: circleBg

            anchors.fill: parent
            radius: width / 2
            color: mouse.containsMouse ? "#1a1a1a" : "#141414"
            border.width: 1
            border.color: mouse.containsMouse ? action.accent : "#2a2a2a"

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }
        }

        Item {
            width: 52
            height: 52
            anchors.centerIn: parent

            Image {
                id: actionIcon

                anchors.fill: parent
                source: action.iconSource
                sourceSize.width: 104
                sourceSize.height: 104
                fillMode: Image.PreserveAspectFit
                smooth: true
                visible: false
                layer.enabled: true
            }

            MultiEffect {
                anchors.fill: actionIcon
                source: actionIcon
                colorization: 1.0
                colorizationColor: mouse.containsMouse ? action.accent : "#bfbfbf"

                Behavior on colorizationColor { ColorAnimation { duration: 120 } }
            }
        }

        // Tooltip label, shown only on hover
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: 14
            }
            width: tipText.implicitWidth + 24
            height: tipText.implicitHeight + 14
            radius: height / 2
            color: "#121212"
            border.color: "#2a2a2a"
            border.width: 1
            opacity: mouse.containsMouse ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                id: tipText

                anchors.centerIn: parent
                text: action.label
                color: "#dddddd"
                font.pixelSize: 13
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: action.activated()
        }
    }
}