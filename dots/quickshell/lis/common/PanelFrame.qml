import QtQuick

// Panel surface with the standard header; children go under it
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    readonly property real headerHeight: header.height
    default property alias content: body.data

    signal closeRequested()

    radius: 12
    color: Theme.panel
    clip: true
    border.color: Theme.border
    border.width: 1

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            id: titleText

            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: root.title
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: Theme.adapt("#ffffff")
        }

        Text {
            anchors.left: titleText.right
            anchors.leftMargin: 8
            anchors.right: closeButton.left
            anchors.rightMargin: 16
            anchors.baseline: titleText.baseline
            elide: Text.ElideRight
            text: root.subtitle
            font.pixelSize: 12
            color: Theme.textDim
        }

        Text {
            id: closeButton

            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            font.pixelSize: 12
            color: closeHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")

            MouseArea {
                id: closeHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }
        }
    }

    Item {
        id: body

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
    }
}
