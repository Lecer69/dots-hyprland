import QtQuick
import QtQuick.Controls
import qs.settings.data
import qs.settings.pages
import qs.settings

ComboBox {
    id: root
    width: 180

    background: Rectangle {
        radius: 8
        color: root.pressed ? "#28ffffff" : root.hovered ? "#1affffff" : "#14ffffff"
        border.color: "#22ffffff"
        border.width: 1
        Behavior on color { ColorAnimation { duration: 100 } }
    }

    contentItem: Text {
        leftPadding: 10
        rightPadding: 28
        text: root.displayText
        font.pixelSize: 12
        color: "#eeffffff"
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Text {
        x: root.width - 20
        y: root.height / 2 - height / 2
        text: "⌄"
        font.pixelSize: 10
        color: "#88ffffff"
    }

    popup: Popup {
        y: root.height + 4
        width: root.width
        padding: 0
        topPadding: 6
        bottomPadding: 6

        background: Rectangle {
            color: "#1e1e1e"
            radius: 10
            border.color: "#22ffffff"
            border.width: 1
            layer.enabled: true
        }

        contentItem: ListView {
            clip: true
            model: root.popup.visible ? root.delegateModel : null
            currentIndex: root.highlightedIndex
            implicitHeight: contentHeight
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }
        }
    }

    delegate: ItemDelegate {
        width: root.width
        height: 34

        background: Rectangle {
            color: highlighted ? "#22ffffff" : "transparent"
            radius: 8
        }

        contentItem: Text {
            text: modelData
            font.pixelSize: 12
            color: "#eeffffff"
            leftPadding: 10
            verticalAlignment: Text.AlignVCenter
        }

        highlighted: root.highlightedIndex === index
    }
}
