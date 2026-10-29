import QtQuick

// A card of the desktop overview: the panel surface with a title row, and an
// optional link (`action`) at its right; children go under it
Rectangle {
    id: root

    property string title: ""
    property string subtitle: ""
    property string action: ""
    readonly property real headerHeight: header.height
    default property alias content: body.data

    signal actionClicked()

    radius: 12
    color: "#0f0f0f"
    border.color: "#1f1f1f"
    border.width: 1

    // Keeps clicks, and the double-click that closes the overview, from the
    // desktop behind
    MouseArea {
        anchors.fill: parent
    }

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
            color: "#ffffff"
        }

        Text {
            anchors.left: titleText.right
            anchors.leftMargin: 8
            anchors.right: actionText.left
            anchors.rightMargin: 16
            anchors.baseline: titleText.baseline
            elide: Text.ElideRight
            text: root.subtitle
            font.pixelSize: 12
            color: "#6b6b6b"
        }

        Text {
            id: actionText

            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.baseline: titleText.baseline
            text: root.action
            font.pixelSize: 12
            color: actionArea.containsMouse ? "#dddddd" : "#666666"

            MouseArea {
                id: actionArea

                anchors.fill: parent
                anchors.margins: -6
                enabled: root.action !== ""
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.actionClicked()
            }
        }
    }

    Item {
        id: body

        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.bottomMargin: 24
    }
}
