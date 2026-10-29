import QtQuick
import Quickshell

// A short commit id that opens the commit on GitHub
Text {
    id: root

    property string sha: ""
    // The repo's page, https://github.com/<owner>/<repo>
    property string webUrl: ""

    text: sha !== "" ? sha.slice(0, 7) : "–"
    font.family: "JetBrainsMono Nerd Font"
    font.pixelSize: 12
    font.underline: area.containsMouse
    color: area.containsMouse ? "#e6e6e6" : "#808080"

    MouseArea {
        id: area
        anchors { fill: parent; margins: -4 }
        enabled: root.sha !== ""
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: Quickshell.execDetached(["xdg-open", root.webUrl + "/commit/" + root.sha])
    }
}
