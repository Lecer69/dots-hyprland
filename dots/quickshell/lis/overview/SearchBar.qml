import QtQuick
import QtQuick.Layouts

SearchPill {
    id: bar

    property bool isClipboard: false
    property bool isEmoji: false
    property bool isOpen: false

    signal queryChanged(string q)
    signal enterPressed()
    signal arrowUp()
    signal arrowDown()
    signal closeRequested()

    function clear()         { input.text = "" }
    function setQuery(text)  { input.text = text }

    implicitHeight: 44
    horizontalPadding: 12

    onIsOpenChanged: if (isOpen) input.forceActiveFocus()

    RowLayout {
        spacing: 10
        width: bar.width - bar.horizontalPadding * 2

        Image {
            width: 18
            height: 18
            Layout.alignment: Qt.AlignVCenter

            sourceSize.width: 18
            sourceSize.height: 18

            fillMode: Image.PreserveAspectFit

            source: {
                if (bar.isClipboard) return "../icons/overview/clipboard.svg"
                if (bar.isEmoji) return "../icons/overview/emoji.svg"
                return "../icons/overview/search.svg"
            }
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: "#dddddd"
            selectionColor: "#444"
            font.pixelSize: 14
            verticalAlignment: TextInput.AlignVCenter
            clip: true

            Text {
                anchors.fill: parent
                text: {
                    if (bar.isClipboard) return "Filter clipboard..."
                    if (bar.isEmoji)     return "Search emojis..."
                    return "Search apps..."
                }
                color: "#666"
                font.pixelSize: parent.font.pixelSize
                verticalAlignment: Text.AlignVCenter
                visible: input.text === ""
            }

            onTextChanged: bar.queryChanged(text)
            Keys.onReturnPressed: bar.enterPressed()

            Keys.onUpPressed: { 
                bar.arrowUp();
                event.accepted = true
            }

            Keys.onDownPressed: {
                bar.arrowDown();
                event.accepted = true
            }

            Keys.onEscapePressed: bar.closeRequested()

            Keys.onDeletePressed: {
                if (input.text === "")
                    bar.closeRequested()
            }
        }

        Text {
            visible: input.text !== ""
            text: "✕"
            color: "#555"
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: input.text = ""
            }
        }
    }
}
