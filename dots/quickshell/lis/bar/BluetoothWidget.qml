import QtQuick
import Quickshell.Io

Item {
    id: root

    implicitWidth: icon.width
    implicitHeight: icon.height

    property string _iconName: "bluetooth-disabled"

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
        command: ["kcmshell6", "kcm_bluetooth"]
    }

    Process {
        id: adapterProc
        command: ["bash", "-c", "bluetoothctl show 2>&1"]

        property string _buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                adapterProc._buffer += data + "\n"
            }
        }

        onExited: function(code, status) {
            const output = adapterProc._buffer
            adapterProc._buffer = ""

            if (code !== 0 || output.includes("No default controller available")) {
                root._iconName = "bluetooth-disabled"
                return
            }

            deviceProc.running = true
        }
    }

    Process {
        id: deviceProc
        command: ["bash", "-c", "bluetoothctl devices Connected 2>&1"]

        property string _buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                deviceProc._buffer += data + "\n"
            }
        }

        onExited: function(code, status) {
            const output = deviceProc._buffer.trim()
            deviceProc._buffer = ""

            if (output === "" || output.includes("No default controller available")) {
                root._iconName = "bluetooth"
                return
            }

            const macRegex = /Device\s+([0-9A-Fa-f:]{17})/g
            const macs = []
            let match
            while ((match = macRegex.exec(output)) !== null) {
                macs.push(match[1])
            }

            if (macs.length === 0) {
                root._iconName = "bluetooth"
                return
            }

            audioCheckProc._macs = macs
            audioCheckProc._index = 0
            audioCheckProc._foundAudio = false
            audioCheckProc._checkNext()
        }
    }

    Process {
        id: audioCheckProc
        property var _macs: []
        property int _index: 0
        property bool _foundAudio: false

        property string _buffer: ""

        stdout: SplitParser {
            onRead: function(data) {
                audioCheckProc._buffer += data + "\n"
            }
        }

        function _checkNext() {
            if (_index >= _macs.length) {
                root._iconName = _foundAudio ? "bluetooth-audio" : "bluetooth-connected"
                return
            }
            command = ["bash", "-c", "bluetoothctl info " + _macs[_index] + " 2>&1"]
            running = true
        }

        onExited: function(code, status) {
            const output = audioCheckProc._buffer.trim()
            audioCheckProc._buffer = ""

            if (output.includes("Icon: audio") || output.includes("Icon: headset") ||
                output.includes("Icon: headphones") || output.includes("Class: 0x240") ||
                output.includes("Class: 0x200") || output.includes("Class: 0x04")) {
                audioCheckProc._foundAudio = true
            }

            audioCheckProc._index++
            audioCheckProc._checkNext()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            if (adapterProc.running || deviceProc.running || audioCheckProc.running) return

            adapterProc._buffer = ""
            adapterProc.running = true
        }
    }
}
