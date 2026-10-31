import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.common

PanelWindow {
    id: root

    property bool isOpen: false
    property var targetScreen: null
    property var pendingAction: null

    // Stays mapped while the buttons fade out
    visible: isOpen || buttonRow.opacity > 0.01
    color: "transparent"
    // Null means the primary screen
    screen: root.targetScreen

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: keyboard.mode
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.namespace: "quickshell:power"

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    PanelKeyboard {
        id: keyboard
        open: root.isOpen
        initialFocus: buttonRow
    }

    Shortcut {
        sequences: ["Escape"]
        onActivated: root.isOpen = false
    }

    // Lets the close animation show before the action runs
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

    Rectangle {
        anchors.fill: parent
        color: "#000000"
        opacity: buttonRow.opacity * 0.5

        MouseArea {
            anchors.fill: parent
            onClicked: root.isOpen = false
        }
    }

    // Nothing picked on open, so a stray Enter does nothing
    Row {
        id: buttonRow

        anchors.centerIn: parent
        spacing: 36

        Keys.onLeftPressed: exitAction.forceActiveFocus()
        Keys.onRightPressed: shutdownAction.forceActiveFocus()

        opacity: root.isOpen ? 1 : 0
        scale: root.isOpen ? 1 : 0.95

        Behavior on opacity { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
        Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

        PowerAction {
            id: shutdownAction

            index: 0
            label: "Shutdown"
            iconSource: "../icons/power.svg"
            accent: Theme.adapt("#f38ba8")
            onActivated: root.run(() => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "shutdown"]))
        }

        PowerAction {
            index: 1
            label: "Reboot"
            iconSource: "../icons/restart.svg"
            accent: Theme.adapt("#89b4fa")
            onActivated: root.run(() => Quickshell.execDetached(["bash", Quickshell.env("HOME") + "/.local/bin/lis", "reboot"]))
        }

        PowerAction {
            index: 2
            label: "Suspend"
            iconSource: "../icons/sleep.svg"
            accent: Theme.adapt("#a6e3a1")
            onActivated: root.run(() => Quickshell.execDetached(["systemctl", "suspend"]))
        }

        PowerAction {
            id: exitAction

            index: 3
            label: "Exit"
            iconSource: "../icons/exit.svg"
            accent: Theme.adapt("#f9e2af")
            onActivated: root.run(() => Hyprland.dispatch("exit"))
        }
    }

    component PowerAction: Item {
        id: action

        property string label: ""
        property string iconSource: ""
        property color accent: Theme.adapt("#ffffff")
        property int index: 0
        signal activated()

        readonly property bool lit: mouse.containsMouse || action.activeFocus

        activeFocusOnTab: true
        Keys.onLeftPressed: action.nextItemInFocusChain(false).forceActiveFocus()
        Keys.onRightPressed: action.nextItemInFocusChain(true).forceActiveFocus()
        Keys.onSpacePressed: action.activated()
        Keys.onReturnPressed: action.activated()
        Keys.onEnterPressed: action.activated()

        width: 128
        height: 128

        // Staggered entrance
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
            color: action.lit ? Theme.adapt("#1a1a1a") : Theme.adapt("#141414")
            border.width: 1
            border.color: action.lit ? action.accent : Theme.adapt("#2a2a2a")

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
                colorizationColor: action.lit ? action.accent : Theme.adapt("#bfbfbf")

                Behavior on colorizationColor { ColorAnimation { duration: 120 } }
            }
        }

        // Label on hover
        Rectangle {
            anchors {
                horizontalCenter: parent.horizontalCenter
                bottom: parent.top
                bottomMargin: 14
            }
            width: tipText.implicitWidth + 24
            height: tipText.implicitHeight + 14
            radius: height / 2
            color: Theme.adapt("#121212")
            border.color: Theme.adapt("#2a2a2a")
            border.width: 1
            opacity: action.lit ? 1 : 0
            visible: opacity > 0.01

            Behavior on opacity { NumberAnimation { duration: 120 } }

            Text {
                id: tipText

                anchors.centerIn: parent
                text: action.label
                color: Theme.adapt("#dddddd")
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