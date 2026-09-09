pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import Qt5Compat.GraphicalEffects
import qs.settings.data

Item {
    id: root

    required property var context
    property bool enableBlur: false
    property real blurSize: 32
    property int blurPasses: 2
    property real brightness: 0.8172
    property string wallpaperPath: ""
    property var blurCache: null

    // Resolved path of the pre-blurred cache image ("" until cached)
    property string blurredSource: ""

    // Key identifies the wallpaper + blur params; changes when either updates
    readonly property string _blurKey: (blurCache !== null && enableBlur && wallpaperPath.length > 0)
        ? blurCache.keyFor(wallpaperPath, blurSize, blurPasses) : ""

    on_BlurKeyChanged: root._refreshBlur()

    function _refreshBlur() {
        if (blurCache === null || _blurKey.length === 0) {
            blurredSource = ""
            return
        }
        // Fast path: reuse a blurred image generated previously (instant lock)
        blurredSource = blurCache.cachedPath(wallpaperPath, blurSize, blurPasses)
        // Slow path handled by the job: if missing/outdated (mtime/size changed),
        // it re-blurs and re-caches, then notifies via onReady
        blurCache.ensureCached(wallpaperPath, blurSize, blurPasses)
    }

    Connections {
        target: root.blurCache

        function onReady(key, path) {
            if (key === root._blurKey)
                root.blurredSource = path
        }
    }

    readonly property color text: "#cdd6f4"
    readonly property color subtext0: '#b8c0e1'
    readonly property color overlay0: '#8b90ac'
    readonly property color red: '#ea7496'
    readonly property color yellow: '#f9da98'

    Rectangle {
        anchors.fill: parent
        color: "transparent"
    }

    // Pre-blurred wallpaper loaded from the disk cache (fast on every lock)
    Image {
        id: wallpaperImage
        anchors.fill: parent
        visible: false
        fillMode: Image.PreserveAspectCrop
        cache: true
        asynchronous: true
        source: (root.enableBlur && root.blurredSource.length > 0)
            ? "file://" + root.blurredSource
            : ""
    }

    BrightnessContrast {
        id: backgroundOutput
        anchors.fill: parent
        source: wallpaperImage
        brightness: root.brightness - 1.0
        contrast: 0
        visible: root.enableBlur && wallpaperImage.status === Image.Ready
        opacity: 0
        Behavior on opacity {
            NumberAnimation {
                duration: 250; easing.type: Easing.OutCubic
            }
        }
    }

    Connections {
        target: wallpaperImage

        function onStatusChanged() {
            if (wallpaperImage.status === Image.Ready && root.enableBlur) {
                backgroundOutput.opacity = 1
            }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: root.enableBlur ? (1 - backgroundOutput.opacity) * 0.6 : 0
        visible: root.enableBlur
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
        Item {
            id: timeWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: timeText.implicitWidth
            height: timeText.implicitHeight

            Text {
                id: timeText
                color: root.text
                font {
                    pixelSize: 108
                    weight: Font.Light
                    letterSpacing: -2
                }
                opacity: 0.92

                function formatted() {
                    return Qt.formatTime(new Date(), "hh:mm")
                }

                text: formatted()
            }
        }

        // Date
        Item {
            id: dateWrap
            anchors.horizontalCenter: parent.horizontalCenter
            width: dateText.implicitWidth
            height: dateText.implicitHeight

            Text {
                id: dateText
                color: root.subtext0
                font {
                    pixelSize: 20
                    weight: Font.Normal
                    letterSpacing: 1.5
                }
                opacity: 0.75

                function formatted() {
                    var d = new Date()
                    var days = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                    var months = ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
                    return days[d.getDay()] + ", " + months[d.getMonth()] + " " + d.getDate()
                }

                text: formatted().toUpperCase()
            }
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
            top: bottomCol.bottom
            topMargin: 10
        }
        text: "✗ Wrong password"
        color: root.red
        font {
            pixelSize: 12
        }
        opacity: 0
        visible: opacity > 0
        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }

        function show() {
            opacity = 1;
            hideTimer.restart()
        }

        Timer {
            id: hideTimer; interval: 2400; onTriggered: errorText.opacity = 0
        }
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
        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "\uf023"
            font {
                pixelSize: 11
            }
            color: root.yellow
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: "Caps Lock is on"
            color: root.yellow
            font {
                pixelSize: 11
            }
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
                    font {
                        pixelSize: 13
                    }
                    color: root.subtext0
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: userCollect.text.trim().length > 0 ? userCollect.text.trim() : "user"
                    color: root.subtext0
                    font {
                        pixelSize: 13
                    }
                }
            }

            Text {
                anchors.verticalCenter: parent.verticalCenter
                text: "·"
                color: root.overlay0
                font {
                    pixelSize: 13
                }
            }

            Row {
                spacing: 6
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "\uf11c"
                    font {
                        pixelSize: 13
                    }
                    color: root.subtext0
                }
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: kbCollect.text.trim().length > 0 ? kbCollect.text.trim() : "en"
                    color: root.subtext0
                    font {
                        pixelSize: 13
                    }
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
                    text: root.context.password.length > 0 ? "●".repeat(root.context.password.length) : "Password..."
                    color: root.context.password.length > 0 ? root.text : root.overlay0
                    font {
                        pixelSize: root.context.password.length > 0 ? 11 : 14
                        letterSpacing: root.context.password.length > 0 ? 4 : 1
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
            } else if (event.key === Qt.Key_A && (event.modifiers & Qt.ControlModifier)) {
                root.context.selectAllClear()
                event.accepted = true
            } else if (event.key === Qt.Key_CapsLock) {
                root.context.capsLockOn = !root.context.capsLockOn
                event.accepted = false
            } else if (event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier)) {
                event.accepted = true
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
        stdout: StdioCollector {
            id: userCollect
        }
    }

    Process {
        id: kbProc
        command: ["bash", "-c", "hyprctl devices -j | jq -r '[.keyboards[]|select(.main)][0].active_keymap // \"en\"'"]
        running: true
        stdout: StdioCollector {
            id: kbCollect
        }
    }
    Timer {
        interval: 5000; running: true; repeat: true
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

    // Power / reboot controls
    Row {
        id: powerRow
        anchors {
            right: parent.right
            bottom: parent.bottom
            rightMargin: 42
            bottomMargin: 42
        }
        spacing: 18

        component PowerButton: Rectangle {
            id: btn
            required property string iconSource
            required property string label
            required property string command
            property bool armed: false

            width: 44
            height: 44
            radius: 22
            color: mouseArea.containsMouse ? "#0A0A0A" : "#0F0F0F"
            border.width: armed ? 1 : 0
            border.color: SettingsData.s.general.accentColor

            Behavior on color {
                ColorAnimation {
                    duration: 120
                }
            }

            Image {
                anchors.centerIn: parent
                source: btn.iconSource
                sourceSize.width: 20
                sourceSize.height: 20
                opacity: 0.9
            }

            // Tooltip / confirm label
            Rectangle {
                visible: mouseArea.containsMouse
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    bottom: parent.top
                    bottomMargin: 8
                }
                width: tipText.implicitWidth + 16
                height: tipText.implicitHeight + 8
                radius: 6
                color: "#121212"

                Text {
                    id: tipText
                    anchors.centerIn: parent
                    text: btn.armed ? "Click again to confirm" : btn.label
                    color: root.text
                    font.pixelSize: 11
                }
            }

            Timer {
                id: disarmTimer
                interval: 2500
                onTriggered: btn.armed = false
            }

            MouseArea {
                id: mouseArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    if (btn.armed) {
                        powerProc.command = ["systemctl", btn.command]
                        powerProc.running = true
                        btn.armed = false
                        disarmTimer.stop()
                    } else {
                        btn.armed = true
                        disarmTimer.restart()
                    }
                }
            }
        }

        PowerButton {
            iconSource: "../icons/restart.svg"
            label: "Reboot"
            command: "reboot"
        }

        PowerButton {
            iconSource: "../icons/power.svg"
            label: "Shut down"
            command: "poweroff"
        }
    }

    Process {
        id: powerProc
        command: []
    }

    Timer {
        interval: 50
        running: true
        repeat: false
        onTriggered: keyItem.forceActiveFocus()
    }
}
