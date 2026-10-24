pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts

Item {
    id: row

    property var entry
    property bool isClipboard: false
    property bool isEmoji: false
    property bool isMath: false
    property bool highlighted: false

    signal entered()
    signal chosen()

    // Clipboard entries are cliphist lines: "<id>\t<preview>" (the type
    // check covers a mode switch, before the old rows are replaced)
    readonly property string clipLine: isClipboard && typeof entry === "string" ? entry : ""
    readonly property var imageInfo: clipLine !== "" ? ClipboardHistory.imageInfo(clipLine) : null
    readonly property bool isImage: imageInfo !== null
    readonly property string thumbUrl: isImage ? (ClipboardHistory.thumbs[ClipboardHistory.idOf(clipLine)] ?? "") : ""

    // Fixed per kind, so rows never resize under the list while it scrolls
    height: isImage ? 72 : 36

    Rectangle {
        anchors.fill: parent
        radius: Math.min(height / 2, 18)
        color: row.highlighted ? "#28ffffff" : hov.containsMouse ? "#14ffffff" : "transparent"
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: row.isImage ? 10 : 8

        Text {
            visible: row.isMath
            text: " ="
            color: '#adadad'
            font.pixelSize: 14
            font.bold: true
            Layout.alignment: Qt.AlignVCenter
        }

        Image {
            visible: !row.isClipboard && !row.isEmoji && !row.isMath
            source: !row.isClipboard && (row.entry?.icon ?? "") !== "" ? "image://icon/" + row.entry.icon : ""
            width: 18
            height: 18
            sourceSize.width: 18
            sourceSize.height: 18
            fillMode: Image.PreserveAspectFit
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: row.isClipboard && !row.isImage
            text: "·"
            color: '#818181'
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
        }

        // Thumbnails are pre-made at 2x this size (ClipboardHistory)
        Rectangle {
            visible: row.isImage
            Layout.preferredWidth: 96
            Layout.preferredHeight: 60
            Layout.alignment: Qt.AlignVCenter
            radius: 6
            color: "#1affffff"
            clip: true

            Image {
                anchors.fill: parent
                source: row.thumbUrl
                sourceSize.width: 192
                sourceSize.height: 120
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 120 } }
            }

            // Thumbnail not made yet
            Text {
                anchors.centerIn: parent
                visible: row.thumbUrl === ""
                text: "…"
                color: "#606060"
                font.pixelSize: 18
            }
        }

        Text {
            Layout.fillWidth: true

            text: {
                if (row.isMath) return row.entry.result
                if (row.isEmoji) return row.entry ?? ""
                if (!row.isClipboard) return row.entry?.name ?? ""
                if (row.isImage) return "Image"
                return ClipboardHistory.textOf(row.clipLine).slice(0, 120)
            }

            // Clipboard text may look like markup; never render it as such
            textFormat: Text.PlainText
            color: row.isMath ? '#e7e7e7' : row.isImage ? "#a0a0a0" : "#dddddd"
            font.pixelSize: row.isMath ? 15 : row.isImage ? 12 : 13
            font.bold: row.isMath
            font.italic: row.isImage
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            readonly property string info: {
                if (row.isMath) return "Click to Copy"
                if (row.isImage) return row.imageInfo.width + "×" + row.imageInfo.height + " · " + row.imageInfo.size
                if (!row.isClipboard && !row.isEmoji) return row.entry?.genericName ?? ""
                return ""
            }

            visible: info !== ""
            text: info
            color: "#b5b5b5"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: hov
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor

        onEntered: row.entered()
        onClicked: row.chosen()
    }
}
