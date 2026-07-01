pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick

Item {
    id: root

    required property var context

    readonly property color text:     "#cdd6f4"
    readonly property color subtext0: '#b8c0e1'
    readonly property color overlay0: '#8b90ac'
    readonly property color red:      '#ea7496'
    readonly property color yellow:   '#f9da98'

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    // Clock and Date
    Column {
        id: clockCol
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 64
        }
        spacing: 6

        // Time
        Text {
            id: timeText
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.text
            font {
                pixelSize: 88
                weight: Font.Light
                letterSpacing: -2
            }
            opacity: 0.92

            function formatted() {
                var d = new Date()
                var h = d.getHours()
                var m = d.getMinutes()
                return Qt.formatTime(d, "hh:mm")
            }
            text: formatted()
        }

        // Date
        Text {
            id: dateText
            anchors.horizontalCenter: parent.horizontalCenter
            color: root.subtext0
            font {
                pixelSize: 15
                weight: Font.Normal
                letterSpacing: 1.5
            }
            opacity: 0.75

            function formatted() {
                var d = new Date()
                var days   = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]
                var months = ["January","February","March","April","May","June",
                              "July","August","September","October","November","December"]
                return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
            }
            text: formatted().toUpperCase()
        }

        Timer {
            interval: 1000
            running: true
            repeat: true
            onTriggered: {
                timeText.text = timeText.formatted()
                dateText.text = dateText.formatted().toUpperCase()
            }
        }
    }

    // Error text
    Text {
        id: errorText
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: capsRow.top
            bottomMargin: 6
        }
        text: "✗ Wrong password"
        color: root.red
        font { pixelSize: 12 }
        opacity: 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 180 } }

        function show() { opacity = 1; hideTimer.restart() }
        Timer { id: hideTimer; interval: 2400; onTriggered: errorText.opacity = 0 }
    }

    // Caps lock warning
    Row {
        id: capsRow
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: bottomCol.top
            bottomMargin: 8
        }
        spacing: 5
        opacity: root.context.capsLockOn ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf023"
            font { pixelSize: 11 }
            color: root.yellow
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Caps Lock is on"
            color: root.yellow
            font { pixelSize: 11 }
        }
    }

    Column {
        id: bottomCol
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom
            bottomMargin: 48
        }
        spacing: 10

        // Username and keyboard layout
        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: 12

            Row {
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf007"
                    font { pixelSize: 13 }
                    color: root.subtext0
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: userCollect.text.trim().length > 0 ? userCollect.text.trim() : "user"
                    color: root.subtext0
                    font { pixelSize: 13 }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                color: root.overlay0
                font { pixelSize: 13 }
            }

            Row {
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf11c"
                    font { pixelSize: 13 }
                    color: root.subtext0
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: kbCollect.text.trim().length > 0 ? kbCollect.text.trim() : "en"
                    color: root.subtext0
                    font { pixelSize: 13 }
                }
            }
        }

        // Password input
        Item {
            id: inputRow
            anchors.horizontalCenter: parent.horizontalCenter
            width: 280
            height: 40

            Rectangle {
                anchors.fill: parent
                radius: 40
                color: '#e30f0f0f'

                Text {
                    anchors {
                        left: parent.left
                        leftMargin: 14
                        right: parent.right
                        rightMargin: 14
                        verticalCenter: parent.verticalCenter
                    }
                    text: root.context.password.length > 0
                          ? "●".repeat(root.context.password.length)
                          : "Password..."
                    color: root.context.password.length > 0 ? root.text : root.overlay0
                    font {
                        pixelSize: root.context.password.length > 0 ? 11 : 14
                        letterSpacing: root.context.password.length > 0 ? 4 : 1
                        family: root.nerdFont
                    }
                    clip: true
                }
            }

            Connections {
                target: root.context
                function onAuthFailed() {
                    errorText.show()
                }
            }
        }
    }

    // Key capture
    Item {
        id: keyItem
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.context.submit()
                event.accepted = true
            } else if (event.key === Qt.Key_Backspace) {
                root.context.backspace()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                root.context.clearPassword()
                event.accepted = true
            } else if (event.key === Qt.Key_CapsLock) {
                root.context.capsLockOn = !root.context.capsLockOn
                event.accepted = false
            } else if (event.text.length > 0 && !event.isAutoRepeat) {
                root.context.appendChar(event.text)
                event.accepted = true
            }
        }
    }

    Process {
        id: userProc
        command: ["id", "-un"]
        running: true
        stdout: StdioCollector { id: userCollect }
    }

    Process {
        id: kbProc
        command: ["bash", "-c", "hyprctl devices -j | jq -r '[.keyboards[]|select(.main)][0].active_keymap // \"en\"'"]
        running: true
        stdout: StdioCollector { id: kbCollect }
    }
    Timer {
        interval: 2000; running: true; repeat: true
        onTriggered: kbProc.running = true
    }

    // Read initial caps lock state
    Process {
        id: capsProc
        command: ["bash", "-c", "cat /sys/class/leds/*capslock*/brightness 2>/dev/null | head -1"]
        running: true
        stdout: StdioCollector {
            id: capsCollect
            onTextChanged: root.context.capsLockOn = capsCollect.text.trim() === "1"
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: keyItem.forceActiveFocus()
    }

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: keyItem.forceActiveFocus()
    }
}
