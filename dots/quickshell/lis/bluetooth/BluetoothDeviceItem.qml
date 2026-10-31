import QtQuick
import QtQuick.Layouts
import Quickshell.Bluetooth
import qs.common

// A device; click to expand its actions
Rectangle {
    id: root

    required property var device
    property bool expanded: false

    // Trust and connect once paired, so it reconnects by itself
    property bool _connectAfterPair: false

    signal toggleRequested()

    readonly property bool busy: device.pairing
        || device.state === BluetoothDeviceState.Connecting
        || device.state === BluetoothDeviceState.Disconnecting
    readonly property bool audio: {
        const name = device.icon ?? ""
        return name.startsWith("audio") || name.includes("headset") || name.includes("headphone")
    }
    readonly property string statusText: {
        if (device.pairing) return "Pairing…"
        if (device.state === BluetoothDeviceState.Connecting) return "Connecting…"
        if (device.state === BluetoothDeviceState.Disconnecting) return "Disconnecting…"
        if (device.connected) return device.batteryAvailable ? Math.round(device.battery * 100) + "%" : "Connected"
        return ""
    }

    function pair(): void {
        root._connectAfterPair = true
        root.device.pair()
    }

    // What its main button would do
    function mainAction(): void {
        if (root.device.pairing)
            root.device.cancelPair()
        else if (!root.device.paired)
            root.pair()
        else if (root.busy)
            return
        else if (root.device.connected)
            root.device.disconnect()
        else
            root.device.connect()
    }

    implicitHeight: column.implicitHeight + 16
    radius: 8
    color: root.expanded && root.activeFocus ? Theme.border
        : root.expanded || rowArea.containsMouse || root.activeFocus ? Theme.hover : "transparent"

    readonly property bool listRow: true
    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: root.toggleRequested()
    Keys.onReturnPressed: root.mainAction()
    Keys.onEnterPressed: root.mainAction()

    Connections {
        target: root.device

        function onPairedChanged() {
            if (!root.device.paired || !root._connectAfterPair) return
            root._connectAfterPair = false
            root.device.trusted = true
            root.device.connect()
        }
    }

    ColumnLayout {
        id: column

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: 8
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        spacing: 8

        Item {
            Layout.fillWidth: true
            implicitHeight: 24

            MouseArea {
                id: rowArea

                anchors.fill: parent
                anchors.topMargin: -8
                anchors.leftMargin: -10
                anchors.rightMargin: -10
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.toggleRequested()
            }

            RowLayout {
                anchors.fill: parent
                spacing: 12

                Icon {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "../icons/" + (root.audio ? "bluetooth-audio" : "bluetooth") + ".svg"
                    sourceSize: Qt.size(16, 16)
                    fillMode: Image.PreserveAspectFit
                    opacity: root.device.connected ? 1 : 0.6
                }

                Text {
                    Layout.fillWidth: true
                    text: root.device.name
                    elide: Text.ElideRight
                    color: root.device.connected ? Theme.adapt("#ffffff") : Theme.text
                    font.pixelSize: 13
                    font.weight: root.device.connected ? Font.Medium : Font.Normal
                }

                Text {
                    visible: text !== ""
                    text: root.statusText
                    color: Theme.textDim
                    font.pixelSize: 12
                }
            }
        }

        RowLayout {
            visible: root.expanded
            Layout.fillWidth: true
            Layout.leftMargin: 28
            Layout.bottomMargin: 2
            spacing: 6

            Text {
                Layout.fillWidth: true
                elide: Text.ElideRight
                text: root.device.address
                color: Theme.textDim
                font.pixelSize: 12
            }

            PanelButton {
                visible: root.device.pairing
                text: "Cancel"
                onClicked: root.device.cancelPair()
            }

            PanelButton {
                visible: !root.device.paired && !root.device.pairing
                text: "Pair"
                onClicked: root.pair()
            }

            PanelButton {
                visible: root.device.paired && !root.busy
                text: root.device.connected ? "Disconnect" : "Connect"
                onClicked: {
                    if (root.device.connected)
                        root.device.disconnect()
                    else
                        root.device.connect()
                }
            }

            PanelButton {
                visible: root.device.paired
                text: "Forget"
                onClicked: root.device.forget()
            }
        }
    }
}
