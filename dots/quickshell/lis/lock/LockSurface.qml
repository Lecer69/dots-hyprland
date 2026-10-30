pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Shapes
import qs.settings.data
import qs.bar

Item {
    id: root

    required property var context
    property bool enableBlur: false
    property real blurSize: 32
    property int blurPasses: 2
    property real brightness: 0.8172
    property string wallpaperPath: ""
    property var blurCache: null

    // Cache entry for this wallpaper and blur ("" when blur is off)
    readonly property string _blurName: (blurCache !== null && enableBlur && wallpaperPath.length > 0)
        ? blurCache.nameFor(wallpaperPath, blurSize, blurPasses) : ""

    // Usually primed before the lock starts; "" until it exists
    readonly property string blurredSource: _blurName.length > 0 ? (blurCache.urls[_blurName] ?? "") : ""

    // Coalesced: settings can change several at once
    on_BlurNameChanged: Qt.callLater(root._requestBlur)

    function _requestBlur() {
        if (_blurName.length === 0) return
        blurCache.prime(wallpaperPath, blurSize, blurPasses)
        blurCache.ensureCached(wallpaperPath, blurSize, blurPasses)
    }

    readonly property color text: "#cdd6f4"
    readonly property color subtext0: '#b8c0e1'
    readonly property color overlay0: '#8b90ac'
    readonly property color red: '#ea7496'
    readonly property color yellow: '#f9da98'

    // Fades only when the blur arrives after the surface
    property bool _fadeEnabled: false

    Component.onCompleted: {
        root._requestBlur()
        Qt.callLater(() => root._fadeEnabled = true)
    }

    Item {
        id: background
        anchors.fill: parent
        visible: root.enableBlur
        opacity: wallpaperImage.status === Image.Ready ? 1 : 0
        Behavior on opacity {
            enabled: root._fadeEnabled
            NumberAnimation {
                duration: 250; easing.type: Easing.OutCubic
            }
        }

        // Cached small, so a synchronous load costs ~1 ms and avoids an empty first frame
        Image {
            id: wallpaperImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectCrop
            asynchronous: false
            cache: true
            source: root.blurredSource
        }

        // Same as BrightnessContrast with contrast 0, without another shader pass
        Rectangle {
            anchors.fill: parent
            color: root.brightness < 1 ? "black" : "white"
            opacity: Math.min(1, Math.abs(root.brightness - 1))
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "#1e1e2e"
        opacity: (1 - background.opacity) * 0.6
        visible: root.enableBlur
    }

    Column {
        id: clockCol
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: 64
        }
        spacing: 6

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
                text: Qt.formatTime(clock.date, "hh:mm")
            }
        }

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

                readonly property var days: ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
                readonly property var months: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]

                text: (days[clock.date.getDay()] + ", " + months[clock.date.getMonth()] + " " + clock.date.getDate()).toUpperCase()
            }
        }

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }

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
                    text: root.context.userName
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
                    text: root.context.keyboardLayout
                    color: root.subtext0
                    font {
                        pixelSize: 13
                    }
                }
            }
        }

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

    Item {
        id: keyItem
        anchors.fill: parent
        focus: true

        Keys.onPressed: (event) => root.context.handleKey(event)
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: keyItem.forceActiveFocus()
    }

    Row {
        id: battRow
        anchors {
            left: parent.left
            bottom: parent.bottom
            leftMargin: 42
            bottomMargin: 42
        }
        spacing: 8
        visible: BatteryData.available
        opacity: 0.9

        readonly property int sz: 24

        function arcColor() {
            if (BatteryData.percent == -100) return '#4a4a4a'
            if (BatteryData.charging) return "#a6e3a1"
            if (BatteryData.percent <= 10) return "#f38ba8"
            if (BatteryData.percent <= 30) return "#fab387"
            return "#89b4fa"
        }

        Item {
            id: battRing
            width: battRow.sz
            height: battRow.sz
            anchors.verticalCenter: parent.verticalCenter

            property real animatedSweep: BatteryData.percent * 3.6
            Behavior on animatedSweep {
                NumberAnimation { duration: 500; easing.type: Easing.InOutQuad }
            }

            Shape {
                anchors.fill: parent
                layer.enabled: true
                layer.samples: 8
                layer.smooth: true
                layer.textureSize: Qt.size(battRow.sz * 2, battRow.sz * 2)
                vendorExtensionsEnabled: true

                ShapePath {
                    strokeColor: Qt.rgba(1, 1, 1, 0.16)
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.FlatCap
                    PathAngleArc {
                        centerX: battRow.sz * 0.5
                        centerY: battRow.sz * 0.5
                        radiusX: battRow.sz * 0.5 - 2
                        radiusY: battRow.sz * 0.5 - 2
                        startAngle: -90
                        sweepAngle: 360
                    }
                }

                ShapePath {
                    strokeColor: battRow.arcColor()
                    strokeWidth: 3
                    fillColor: "transparent"
                    capStyle: ShapePath.RoundCap
                    PathAngleArc {
                        centerX: battRow.sz * 0.5
                        centerY: battRow.sz * 0.5
                        radiusX: battRow.sz * 0.5 - 2
                        radiusY: battRow.sz * 0.5 - 2
                        startAngle: -90
                        sweepAngle: battRing.animatedSweep
                    }
                }
            }

            Rectangle {
                visible: BatteryData.charging
                width: 7
                height: 7
                radius: 3.5
                color: battRow.arcColor()
                antialiasing: true
                anchors.centerIn: parent
            }
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: BatteryData.percent + "%"
            color: root.subtext0
            font {
                pixelSize: 13
            }
        }
    }

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
