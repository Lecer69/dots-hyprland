pragma ComponentBehavior: Bound

import QtQuick

Item {
    id: root

    property real columnHeight: 600

    readonly property color accentColor: "#f38ba8"

    implicitWidth: flow.implicitWidth
    implicitHeight: Math.min(flow.implicitHeight, root.columnHeight)

    Flow {
        id: flow
        anchors.left: parent.left
        anchors.top: parent.top
        flow: Flow.TopToBottom
        spacing: 20
        height: root.columnHeight

        Repeater {
            model: [...CheatsheetService.keybindCategories, ""]
            delegate: CheatsheetCategory {
                required property var modelData
                categoryName: modelData
                accentColor: root.accentColor
            }
        }
    }
}