import QtQuick
import QtQuick.Layouts
import Quickshell.Networking
import qs.common

// A network; click to expand its actions
Rectangle {
    id: root

    required property var network
    property bool expanded: false
    property string failure: ""

    signal toggleRequested()
    signal passwordRequested()

    readonly property int signalLevel: Math.round(network.signalStrength * 100)
    readonly property bool secured: network.security !== WifiSecurityType.Open
        && network.security !== WifiSecurityType.Owe
    // 802.1X needs more than a password
    readonly property bool enterprise: [WifiSecurityType.Wpa2Eap, WifiSecurityType.WpaEap,
        WifiSecurityType.Wpa3SuiteB192, WifiSecurityType.DynamicWep, WifiSecurityType.Leap].includes(network.security)
    readonly property bool unsupported: enterprise && !network.known

    readonly property string statusText: {
        if (root.failure !== "") return root.failure
        if (network.state === ConnectionState.Connecting) return "Connecting…"
        if (network.state === ConnectionState.Disconnecting) return "Disconnecting…"
        if (network.connected) return "Connected"
        if (network.known) return "Saved"
        return ""
    }

    function failureText(reason): string {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
            return "Password required"
        case ConnectionFailReason.WifiClientFailed:
        case ConnectionFailReason.WifiAuthTimeout:
            return "Couldn't connect, check the password"
        case ConnectionFailReason.WifiNetworkLost:
            return "Network out of range"
        case ConnectionFailReason.WifiClientDisconnected:
            return "Disconnected by the network"
        default:
            return "Couldn't connect"
        }
    }

    function connect(): void {
        root.failure = ""
        if (root.secured && !root.enterprise && !root.network.known)
            root.passwordRequested()
        else
            root.network.connect()
    }

    // What its main button would do
    function mainAction(): void {
        if (root.network.connected)
            root.network.disconnect()
        else if (!root.unsupported)
            root.connect()
    }

    function iconName(): string {
        if (root.signalLevel <= 20) return "wifi-1b"
        if (root.signalLevel <= 40) return "wifi-2b"
        if (root.signalLevel <= 60) return "wifi-3b"
        if (root.signalLevel <= 80) return "wifi-4b"
        return "wifi-5b"
    }

    implicitHeight: column.implicitHeight + 16
    radius: 8
    color: root.expanded && root.activeFocus ? "#1f1f1f"
        : root.expanded || rowArea.containsMouse || root.activeFocus ? "#161616" : "transparent"

    readonly property bool listRow: true
    activeFocusOnTab: true
    Keys.onUpPressed: KeyNav.step(root, false)
    Keys.onDownPressed: KeyNav.step(root, true)
    Keys.onSpacePressed: root.toggleRequested()
    Keys.onReturnPressed: root.mainAction()
    Keys.onEnterPressed: root.mainAction()

    Connections {
        target: root.network

        function onConnectionFailed(reason) {
            root.failure = root.failureText(reason)
        }

        function onConnectedChanged() {
            if (root.network.connected)
                root.failure = ""
        }
    }

    IpAddressProbe {
        id: ip

        device: root.network.device ? root.network.device.name : ""
        active: root.expanded && root.network.connected
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

                Image {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    source: "../icons/" + root.iconName() + ".svg"
                    sourceSize: Qt.size(16, 16)
                    fillMode: Image.PreserveAspectFit
                    opacity: root.network.connected ? 1 : 0.6
                }

                Text {
                    Layout.fillWidth: true
                    text: root.network.name
                    elide: Text.ElideRight
                    color: root.network.connected ? "#ffffff" : "#e6e6e6"
                    font.pixelSize: 13
                    font.weight: root.network.connected ? Font.Medium : Font.Normal
                }

                Image {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    visible: root.secured
                    source: "../icons/lock.svg"
                    sourceSize: Qt.size(12, 12)
                    fillMode: Image.PreserveAspectFit
                    opacity: 0.35
                }

                Text {
                    visible: text !== ""
                    text: root.statusText
                    color: root.failure !== "" ? "#e06c6c" : "#6b6b6b"
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
                color: "#6b6b6b"
                font.pixelSize: 12
                text: {
                    if (root.unsupported) return "Enterprise networks aren't supported here"
                    const parts = ["Signal " + root.signalLevel + "%"]
                    if (root.network.connected && ip.address !== "") parts.push(ip.address)
                    return parts.join(" · ")
                }
            }

            PanelButton {
                visible: root.network.connected
                text: "Disconnect"
                onClicked: root.network.disconnect()
            }

            PanelButton {
                visible: !root.network.connected && !root.unsupported
                text: "Connect"
                onClicked: root.connect()
            }

            PanelButton {
                visible: root.network.known
                text: "Forget"
                onClicked: root.network.forget()
            }
        }
    }
}
