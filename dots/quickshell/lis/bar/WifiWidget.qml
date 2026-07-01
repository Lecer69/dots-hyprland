import QtQuick
import Quickshell.Io

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: icon.height

    property string _iconName: "wifi-disconnect"
    property string _connType: ""

    Image {
        id: icon
        source: "../icons/" + root._iconName + ".svg"
        width: 18
        height: 18
        mipmap: true
        antialiasing: true
        fillMode: Image.PreserveAspectFit
        anchors.verticalCenter: parent.verticalCenter
        opacity: menuBtn.containsMouse ? 0.7 : 1.0
    }

    MouseArea {
        id: menuBtn
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: if (!kcmProc.running) kcmProc.running = true
    }

    Process {
        id: kcmProc
        command: ["kcmshell6", "kcm_networkmanagement"]
    }

    Process {
        id: typeProc
        command: ["bash", "-c", "nmcli -t -f TYPE,STATE device 2>&1"]

        property string _buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                typeProc._buffer += data + "\n"
            }
        }

        onExited: function(code, status) {
            const lines = typeProc._buffer.trim().split("\n")
            typeProc._buffer = ""

            let hasEthernet = false
            let hasWifi = false

            for (const line of lines) {
                if (line.trim() === "") continue

                const parts = line.split(":")
                if (parts.length < 2) continue

                const type = parts[0].trim().toLowerCase()
                const state = parts.slice(1).join(":").trim().toLowerCase()

                if (type === "ethernet" && state.startsWith("connected"))
                    hasEthernet = true

                if (type === "wifi" && state.startsWith("connected"))
                    hasWifi = true
            }

            if (hasEthernet) {
                root._iconName = "ethernet"
            } else if (hasWifi) {
                root._connType = "wifi"
                signalProc.running = true
            } else {
                root._iconName = "wifi-disconnect"
            }
        }
    }

    Process {
        id: signalProc
        command: ["bash", "-c", "nmcli -t -f SIGNAL,ACTIVE device wifi 2>&1"]

        property string _buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                signalProc._buffer += data + "\n"
            }
        }

        onExited: function(code, status) {
            const lines = signalProc._buffer.trim().split("\n")
            signalProc._buffer = ""

            for (const line of lines) {
                if (line.trim() === "") continue

                const parts = line.split(":")
                if (parts.length < 2) continue

                const signal = parseInt(parts[0].trim(), 10)
                const active = parts[1].trim().toLowerCase()

                if (active === "yes" && !isNaN(signal)) {
                    if (signal <= 20) { root._iconName = "wifi-1b"; return }
                    if (signal <= 40) { root._iconName = "wifi-2b"; return }
                    if (signal <= 60) { root._iconName = "wifi-3b"; return }
                    if (signal <= 80) { root._iconName = "wifi-4b"; return }
                    root._iconName = "wifi-5b"
                    return
                }
            }

            root._iconName = "wifi-disconnect"
        }
    }

    Timer {
        interval: 5000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            typeProc._buffer = ""
            typeProc.running = true
        }
    }
}