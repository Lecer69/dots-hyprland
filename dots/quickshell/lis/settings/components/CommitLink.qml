import QtQuick
import Quickshell
import qs.common

// A short commit id that opens the commit on GitHub
Text {
    id: root

    property string sha: ""
    // https://github.com/<owner>/<repo>
    property string webUrl: ""

    readonly property bool lit: area.containsMouse || root.activeFocus

    function open(): void {
        Quickshell.execDetached(["xdg-open", root.webUrl + "/commit/" + root.sha])
    }

    text: sha !== "" ? sha.slice(0, 7) : "–"
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    font.underline: root.lit
    color: root.lit ? Theme.text : Theme.adapt("#808080")

    activeFocusOnTab: root.sha !== ""
    Keys.onReturnPressed: root.open()
    Keys.onEnterPressed: root.open()
    Keys.onSpacePressed: root.open()

    MouseArea {
        id: area
        anchors { fill: parent; margins: -4 }
        enabled: root.sha !== ""
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.open()
    }
}
