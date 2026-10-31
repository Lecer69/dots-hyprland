import QtQuick
import QtQuick.Effects
import qs.common

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
    // Defaults are the plain grey look
    property color accentColor: Theme.text
    property color accentIconColor: Theme.panel
    property color activeColor: Theme.border
    property color hoverColor: Theme.hover
    property color iconColor: Theme.adapt("#bbbbbb")
    property color activeIconColor: Theme.adapt("#ffffff")
    signal clicked()

    readonly property bool showPrimary: !(iconAlt !== "" && useAlt)

    width: size
    height: size

    readonly property bool lit: (mouse.containsMouse || root.activeFocus) && root.enabled

    activeFocusOnTab: root.enabled
    Keys.onSpacePressed: if (root.enabled) root.clicked()
    Keys.onReturnPressed: if (root.enabled) root.clicked()
    Keys.onEnterPressed: if (root.enabled) root.clicked()

    opacity: root.enabled ? 1.0 : 0.35
    Behavior on opacity { NumberAnimation { duration: 120 } }

    Rectangle {
        id: bg

        anchors.fill: parent
        radius: width / 2
        color: root.accent
            ? (mouse.pressed ? Qt.darker(root.accentColor, 1.15) : root.lit ? Qt.lighter(root.accentColor, 1.1) : root.accentColor)
            : root.active ? (root.activeFocus ? Qt.lighter(root.activeColor, 1.25) : root.activeColor)
            : (root.lit ? root.hoverColor : "transparent")
    }

    Item {
        anchors.centerIn: parent
        width: root.iconSize
        height: root.iconSize

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
            colorizationColor: root.accent ? root.accentIconColor : root.active ? root.activeIconColor : root.iconColor
            opacity: root.showPrimary ? 1 : 0

            Behavior on opacity { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
        }

        // Crossfades in when useAlt is set
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
            colorizationColor: root.accent ? root.accentIconColor : root.active ? root.activeIconColor : root.iconColor
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