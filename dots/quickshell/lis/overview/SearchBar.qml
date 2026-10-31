import QtQuick
import QtQuick.Layouts
import qs.common

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

    implicitHeight: 40
    horizontalPadding: 12

    onIsOpenChanged: {
        if (!isOpen) return
        input.forceActiveFocus()
        iconPop.restart()
    }

    RowLayout {
        spacing: 10
        width: bar.width - bar.horizontalPadding * 2

        Icon {
            id: modeIcon

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

            // Spins in on opening and on mode changes
            onSourceChanged: iconPop.restart()

            ParallelAnimation {
                id: iconPop
                NumberAnimation { target: modeIcon; property: "scale"; from: 0.4; to: 1; duration: 340; easing.type: Easing.OutBack }
                NumberAnimation { target: modeIcon; property: "rotation"; from: -120; to: 0; duration: 340; easing.type: Easing.OutCubic }
                NumberAnimation { target: modeIcon; property: "opacity"; from: 0; to: 1; duration: 200; easing.type: Easing.OutCubic }
            }
        }

        TextInput {
            id: input
            Layout.fillWidth: true
            color: Theme.text
            selectionColor: Theme.adapt("#444444")
            font.pixelSize: 14
            verticalAlignment: TextInput.AlignVCenter
            clip: true

            // A gliding caret that fades instead of blinking
            cursorDelegate: Item {
                property real lastX: 0

                width: 2
                visible: input.cursorVisible

                // Starts where the line was drawn, lit while typing
                onXChanged: {
                    caretLine.x += lastX - x
                    lastX = x
                    glide.restart()
                    caretLine.opacity = 1
                    pulse.restart()
                }

                Rectangle {
                    id: caretLine
                    width: 2
                    height: parent.height
                    radius: 1
                    color: Theme.text
                }

                NumberAnimation {
                    id: glide
                    target: caretLine
                    property: "x"
                    to: 0
                    duration: 110
                    easing.type: Easing.OutCubic
                }

                SequentialAnimation {
                    id: pulse
                    running: input.cursorVisible
                    loops: Animation.Infinite
                    PauseAnimation { duration: 500 }
                    NumberAnimation { target: caretLine; property: "opacity"; to: 0; duration: 380; easing.type: Easing.InOutSine }
                    NumberAnimation { target: caretLine; property: "opacity"; to: 1; duration: 380; easing.type: Easing.InOutSine }
                }
            }

            Text {
                anchors.fill: parent
                text: {
                    if (bar.isClipboard) return "Filter clipboard..."
                    if (bar.isEmoji)     return "Search emojis..."
                    return "Search apps..."
                }
                color: Theme.textDim
                font.pixelSize: parent.font.pixelSize
                verticalAlignment: Text.AlignVCenter
                // Slides away as typing starts
                opacity: input.text === "" ? 1 : 0
                visible: opacity > 0
                transform: Translate {
                    x: input.text === "" ? 0 : 16
                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                }
                Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            }

            onTextChanged: bar.queryChanged(text)
            Keys.onReturnPressed: bar.enterPressed()

            Keys.onUpPressed: event => {
                bar.arrowUp();
                event.accepted = true
            }

            Keys.onDownPressed: event => {
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
            readonly property bool shown: input.text !== ""

            visible: opacity > 0
            opacity: shown ? 1 : 0
            scale: shown ? 1 : 0.4
            rotation: shown ? 0 : -90
            Behavior on opacity { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
            Behavior on scale { NumberAnimation { duration: 240; easing.type: Easing.OutBack } }
            Behavior on rotation { NumberAnimation { duration: 240; easing.type: Easing.OutCubic } }

            text: "✕"
            color: clearHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
            font.pixelSize: 12
            Layout.alignment: Qt.AlignVCenter

            MouseArea {
                id: clearHover
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: input.text = ""
            }
        }
    }
}
