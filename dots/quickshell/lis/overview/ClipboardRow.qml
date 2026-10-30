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

    // cliphist lines: "<id>\t<preview>"
    readonly property string clipLine: isClipboard && typeof entry === "string" ? entry : ""
    readonly property var imageInfo: clipLine !== "" ? ClipboardHistory.imageInfo(clipLine) : null
    readonly property bool isImage: imageInfo !== null
    readonly property string thumbUrl: isImage ? (ClipboardHistory.thumbs[ClipboardHistory.idOf(clipLine)] ?? "") : ""

    // "<emoji> <name and keywords>"
    readonly property string emojiLine: isEmoji && typeof entry === "string" ? entry : ""
    readonly property string emoji: emojiLine.split(" ")[0]

    // 0 to 1 as the row arrives; the list starts it
    property real appear: 1

    function enter(delay: int): void {
        appear = 0
        appearDelay.duration = delay
        appearAnim.restart()
    }

    SequentialAnimation {
        id: appearAnim
        PauseAnimation { id: appearDelay }
        NumberAnimation { target: row; property: "appear"; to: 1; duration: 280; easing.type: Easing.OutCubic }
    }

    // 0 to 1 once picked: the icon zooms out as the launcher closes
    property real launchProgress: 0

    function launch(): void { launchAnim.restart() }

    // Fixed per kind, so rows never resize while scrolling
    height: isImage ? 72 : 36
    // Above the highlight; a launching row above the rest
    z: launchProgress > 0 ? 2 : 1

    onHighlightedChanged: if (highlighted && isEmoji) wiggle.restart()

    // Linear; the icon eases on its own curves
    NumberAnimation {
        id: launchAnim
        target: row
        property: "launchProgress"
        from: 0
        to: 1
        duration: 380
    }
    readonly property real launchGrowth: 1 + 1.6 * (1 - Math.pow(1 - launchProgress, 3))
    readonly property real launchFade: 1 - launchProgress * launchProgress

    // Hover; the list draws the selection
    Rectangle {
        anchors.fill: parent
        radius: 8
        opacity: row.appear
        color: hov.containsMouse && !row.highlighted ? "#161616" : "transparent"
        Behavior on color { ColorAnimation { duration: 120 } }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: row.isImage ? 10 : 8
        opacity: row.appear

        transform: [
            Translate {
                x: row.highlighted ? 3 : 0
                Behavior on x { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            },
            Translate { x: (1 - row.appear) * 24 }
        ]

        Text {
            visible: row.isMath
            text: " ="
            color: "#808080"
            font.pixelSize: 14
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
            scale: row.highlighted ? 1.15 : 1
            Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            opacity: row.launchFade
            transform: Scale {
                origin.x: 9
                origin.y: 9
                xScale: row.launchGrowth
                yScale: row.launchGrowth
            }
        }

        Text {
            id: glyph

            visible: row.isEmoji
            text: row.emoji
            font.pixelSize: 18
            horizontalAlignment: Text.AlignHCenter
            Layout.preferredWidth: 24
            Layout.alignment: Qt.AlignVCenter
            scale: row.highlighted ? 1.25 : 1
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutBack } }
            opacity: row.launchFade
            transform: Scale {
                origin.x: glyph.width / 2
                origin.y: glyph.height / 2
                xScale: row.launchGrowth
                yScale: row.launchGrowth
            }

            SequentialAnimation {
                id: wiggle
                NumberAnimation { target: glyph; property: "rotation"; to: -12; duration: 70; easing.type: Easing.OutQuad }
                NumberAnimation { target: glyph; property: "rotation"; to: 9; duration: 110; easing.type: Easing.InOutQuad }
                NumberAnimation { target: glyph; property: "rotation"; to: 0; duration: 130; easing.type: Easing.OutQuad }
            }
        }

        Text {
            visible: row.isClipboard && !row.isImage
            text: "·"
            color: "#4a4a4a"
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
        }

        // Thumbnails are made at 2x this size
        Rectangle {
            visible: row.isImage
            Layout.preferredWidth: 96
            Layout.preferredHeight: 60
            Layout.alignment: Qt.AlignVCenter
            radius: 6
            color: "#161616"
            clip: true

            Image {
                anchors.fill: parent
                source: row.thumbUrl
                sourceSize.width: 192
                sourceSize.height: 120
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                opacity: status === Image.Ready ? 1 : 0
                scale: status !== Image.Ready ? 0.92 : row.highlighted ? 1.06 : 1
                Behavior on opacity { NumberAnimation { duration: 180 } }
                Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }
            }

            // Not made yet
            Text {
                anchors.centerIn: parent
                visible: row.thumbUrl === ""
                text: "…"
                color: "#4a4a4a"
                font.pixelSize: 18
            }
        }

        Text {
            Layout.fillWidth: true

            text: {
                if (row.isMath) return row.entry.result
                if (row.isEmoji) return row.emojiLine.slice(row.emoji.length + 1)
                if (!row.isClipboard) return row.entry?.name ?? ""
                if (row.isImage) return "Image"
                return ClipboardHistory.textOf(row.clipLine).slice(0, 120)
            }

            // Clipboard text may look like markup
            textFormat: Text.PlainText
            color: row.isMath ? "#ffffff" : row.isImage ? "#999999" : row.highlighted ? "#ffffff" : "#e6e6e6"
            Behavior on color { ColorAnimation { duration: 140 } }
            font.pixelSize: row.isMath ? 15 : row.isImage ? 12 : 13
            font.weight: row.isMath ? Font.DemiBold : Font.Normal
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
            color: "#6b6b6b"
            font.pixelSize: 12
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
