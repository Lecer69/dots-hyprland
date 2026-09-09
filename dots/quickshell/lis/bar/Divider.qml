import QtQuick

Rectangle {
    id: divider

    property bool vertical: false

    width: vertical ? 15 : 1
    height: vertical ? 1 : 15
    radius: 0.5
    color: "#0c0c0c"
}