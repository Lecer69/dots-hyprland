import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string icon: "play"
    property string iconAlt: ""
    property bool useAlt: false
    property int size: 44
    property int iconSize: 18
    property bool accent: false
    property bool active: false
    property bool enabled: true
    signal clicked()

    readonly property bool showPrimary: !(iconAlt !== "" && useAlt)

    width: size
    height: size

    opacity: root.enabled ? 1.0 : 0.35
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: width / 2
        color: root.accent
            ? (mouse.pressed ? "#cccccc" : mouse.containsMouse && root.enabled ? "#ffffff" : "#e6e6e6")
            : root.active ? "#1f1f1f"
            : (mouse.containsMouse && root.enabled ? "#161616" : "transparent")
    }

    Item {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize

        // Primary icon
        Image {
            id: iconPrimary

            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: "../icons/media-" + root.icon + "-symbolic.svg"
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: iconPrimary
            source: iconPrimary
            colorization: 1.0
            colorizationColor: root.accent ? "#0f0f0f" : root.active ? "#ffffff" : "#bbbbbb"
            opacity: root.showPrimary ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        // Secondary icon (crossfades in when useAlt is set)
        Image {
            id: iconSecondary

            anchors.centerIn: parent
            width: root.iconSize
            height: root.iconSize
            source: root.iconAlt !== "" ? "../icons/media-" + root.iconAlt + "-symbolic.svg" : ""
            sourceSize.width: width
            sourceSize.height: height
            smooth: true
            visible: false
            layer.enabled: true
        }

        MultiEffect {
            anchors.fill: iconSecondary
            source: iconSecondary
            colorization: 1.0
            colorizationColor: root.accent ? "#0f0f0f" : root.active ? "#ffffff" : "#bbbbbb"
            opacity: root.showPrimary ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }
    }

    scale: mouse.pressed ? 0.92 : 1.0
    Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutQuad } }

    MouseArea {
        id: mouse

        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        enabled: root.enabled
        onClicked: root.clicked()
    }
}