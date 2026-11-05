import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.common
import qs.settings.data

// The lock screen as a thumbnail; its blur and brightness follow the settings without a cached image
ClippingRectangle {
    id: root

    readonly property var lock: SettingsData.s.lockScreen
    readonly property string wallpaper: screenLock.wallpaperFor(QsWindow.window?.screen?.name ?? "")

    // The cached image's blur, at this size; a blurMax of 9 sigma looks the closest to it
    readonly property real blurRadius: Math.min(64, root.lock.blurSize / 2 * Math.sqrt(root.lock.blurPasses) * stage.factor * 9)

    radius: 8
    color: "black"
    border.width: 1
    border.color: Theme.border

    Item {
        anchors.fill: parent
        visible: root.lock.enableBlur

        Image {
            id: image

            anchors.fill: parent
            source: root.wallpaper === "" ? "" : "file://" + root.wallpaper.split("/").map(encodeURIComponent).join("/")
            sourceSize.width: 640
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: image
            source: image
            visible: image.status === Image.Ready
            autoPaddingEnabled: false
            blurEnabled: true
            // At a low blur value it mixes in the sharp image, so the maximum follows the radius
            blurMax: Math.max(2, Math.ceil(root.blurRadius))
            blur: root.blurRadius / blurMax
        }

        Rectangle {
            anchors.fill: parent
            color: root.lock.brightness < 1 ? "black" : "white"
            opacity: Math.min(1, Math.abs(root.lock.brightness - 1))
        }
    }

    // Same layout as LockSurface, at screen size and scaled as a whole
    Item {
        id: stage

        readonly property real factor: Math.max(0.01, root.width / width)

        width: 1920
        height: 1080
        scale: factor
        transformOrigin: Item.TopLeft

        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: 64
            spacing: 6

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: "#cdd6f4"
                opacity: 0.92
                font.pixelSize: 108
                font.weight: Font.Light
                font.letterSpacing: -2
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: Qt.formatDate(clock.date, "dddd, MMMM d").toUpperCase()
                color: "#b8c0e1"
                opacity: 0.75
                font.pixelSize: 20
                font.letterSpacing: 1.5
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            spacing: 10

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                text: "  " + (Quickshell.env("USER") ?? "user") + "   ·     en"
                color: "#b8c0e1"
                font.pixelSize: 13
            }

            Rectangle {
                width: 280
                height: 40
                radius: 40
                color: "#e30f0f0f"

                Text {
                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Password..."
                    color: "#8b90ac"
                    font.pixelSize: 14
                    font.letterSpacing: 1
                }
            }
        }

        Row {
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.rightMargin: 42
            anchors.bottomMargin: 42
            spacing: 18

            Repeater {
                model: ["restart", "power"]

                Rectangle {
                    required property string modelData

                    width: 44
                    height: 44
                    radius: 22
                    color: "#0f0f0f"

                    Image {
                        anchors.centerIn: parent
                        source: "../../icons/" + parent.modelData + ".svg"
                        sourceSize: Qt.size(20, 20)
                        opacity: 0.9
                    }
                }
            }
        }
    }
}
