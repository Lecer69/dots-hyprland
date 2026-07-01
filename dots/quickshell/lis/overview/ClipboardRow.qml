pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import Quickshell.Io

Item {
    id: row

    property var entry
    property bool isClipboard: false
    property bool isEmoji: false
    property bool isMath: false
    property bool isImage: false
    property bool highlighted: false

    signal entered()
    signal chosen()

    height: isImage ? imageThumb.visible ? 72 : 36 : 36

    Behavior on height { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // Decode image to a temp file and load it as a source
    property string _thumbPath: ""
    property bool   _thumbLoading: false

    Process {
        id: decodeProc
        property string entryId: ""
        command: ["sh", "-c",
            "cliphist decode " + JSON.stringify(decodeProc.entryId) +
            " > /tmp/qs-clip-thumb-" + JSON.stringify(decodeProc.entryId).replace(/\W/g,"") + ".png" +
            " && echo /tmp/qs-clip-thumb-" + JSON.stringify(decodeProc.entryId).replace(/\W/g,"") + ".png"]
        running: false
        stdout: StdioCollector {
            id: decodeOut
            onTextChanged: {
                const p = decodeOut.text.trim()
                if (p !== "") {
                    row._thumbPath = "file://" + p
                    row._thumbLoading = false
                }
            }
        }
    }

    onIsImageChanged: {
        if (isImage && row._thumbPath === "" && !row._thumbLoading) {
            row._thumbLoading = true
            decodeProc.entryId = (row.entry ?? "").split("\t")[0]
            decodeProc.running = true
        }
    }

    Component.onCompleted: {
        if (isImage && row._thumbPath === "" && !row._thumbLoading) {
            row._thumbLoading = true
            decodeProc.entryId = (row.entry ?? "").split("\t")[0]
            decodeProc.running = true
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: row.highlighted ? "#28ffffff" : hov.containsMouse ? "#14ffffff" : "transparent"
    }

    // Image thumbnail
    RowLayout {
        id: imageLayout
        visible: row.isImage
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
            topMargin: 6
            bottomMargin: 6
        }
        spacing: 10

        Rectangle {
            id: imageThumb
            visible: row._thumbPath !== ""
            width:  visible ? 96 : 0
            height: 60
            radius: 6
            color: "#1affffff"
            clip: true
            Layout.alignment: Qt.AlignVCenter

            Image {
                anchors.fill: parent
                source: row._thumbPath
                fillMode: Image.PreserveAspectFit
                smooth: true
                asynchronous: true
            }
        }

        // Spinner while decoding
        Rectangle {
            visible: row._thumbLoading && row._thumbPath === ""
            width: 96; height: 60
            radius: 6
            color: "#1affffff"
            Layout.alignment: Qt.AlignVCenter

            Text {
                anchors.centerIn: parent
                text: "…"
                color: "#606060"
                font.pixelSize: 18
            }
        }

        Text {
            Layout.fillWidth: true
            text: "Image"
            color: "#a0a0a0"
            font.pixelSize: 12
            font.italic: true
            verticalAlignment: Text.AlignVCenter
        }
    }

    // Normal
    RowLayout {
        visible: !row.isImage
        anchors {
            fill: parent
            leftMargin: 10
            rightMargin: 10
        }
        spacing: 8

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
            visible: row.isClipboard
            text: "·"
            color: '#818181'
            font.pixelSize: 18
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            Layout.fillWidth: true

            text: {
                if (row.isMath) return row.entry.result
                if (row.isEmoji) return row.entry ?? ""
                if (!row.isClipboard) return row.entry?.name ?? ""
                return (row.entry ?? "").replace(/^\S+\t/, "").slice(0, 120)
            }

            color: row.isMath ? '#e7e7e7' : "#dddddd"
            font.pixelSize: row.isMath ? 15 : 13
            font.bold: row.isMath
            elide: Text.ElideRight
            verticalAlignment: Text.AlignVCenter
        }

        Text {
            visible: row.isMath
            text: "Click to Copy"
            color: "#b5b5b5"
            font.pixelSize: 11
            Layout.alignment: Qt.AlignVCenter
        }

        Text {
            visible: !row.isClipboard && !row.isMath && (row.entry?.genericName ?? "") !== ""
            text: row.entry?.genericName ?? ""
            color: '#b5b5b5'
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
