import QtQuick
import QtQuick.Effects

Item {
    id: root

    property string icon: "play"
    property bool big: false
    property bool enabled: true
    signal clicked()

    readonly property int size: big ? 38 : 26
    width: size
    height: size

    Image {
        id: iconImg
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -1
        width: root.size
        height: width
        source: "../icons/media-" + root.icon + "-symbolic.svg"
        sourceSize.width: width * 2
        sourceSize.height: height * 2
        smooth: true
        opacity: 0
        layer.enabled: true
    }

    MultiEffect {
        anchors.fill: iconImg
        source: iconImg
        colorization: 1.0
        colorizationColor: "#cdd6f4"
        opacity: root.enabled ? 1.0 : 0.3
        Behavior on opacity { NumberAnimation { duration: 120 } }
    }

    scale: mouse.pressed ? 0.9 : 1.0
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
