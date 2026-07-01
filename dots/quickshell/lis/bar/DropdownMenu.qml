import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    property int menuWidth:  130
    property int barHeight:  36
    property list<QtObject> items: []
    property var targetScreen: null

    screen: targetScreen ?? Quickshell.screens[0]

    property bool isOpen: false

    readonly property int itemHeight:  26
    readonly property int paddingV:    5
    readonly property int panelHeight: items.length * itemHeight + paddingV * 2 + (items.length - 1) * 2

    visible: true
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: isOpen ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

    anchors.top:    true
    anchors.bottom: true
    anchors.left:   true
    anchors.right:  true

    exclusionMode: ExclusionMode.Ignore

    mask: Region {
        item: panel.opacity > 0 ? panel : null
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        enabled: root.isOpen
        onClicked: root.isOpen = false
    }

    Rectangle {
        id: panel

        opacity: root.isOpen ? 1.0 : 0.0
        visible: opacity > 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }

        anchors.top:         parent.top
        anchors.right:       parent.right
        anchors.topMargin:   root.barHeight + 4
        anchors.rightMargin: 8

        width:  root.menuWidth
        height: root.panelHeight

        radius: 10
        color:  "#e2121212"
        border.width: 1
        border.color: "#40ffffff"

        Column {
            id: itemColumn
            anchors {
                top:         parent.top
                left:        parent.left
                right:       parent.right
                topMargin:   root.paddingV
                leftMargin:  4
                rightMargin: 4
            }
            spacing: 2

            Repeater {
                model: root.items

                MenuItem {
                    width:  itemColumn.width
                    label:  modelData.label
                    icon:   modelData.icon
                    onTriggered: {
                        root.isOpen = false
                        modelData.action()
                    }
                }
            }
        }
    }
}