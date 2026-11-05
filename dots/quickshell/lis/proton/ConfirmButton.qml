import QtQuick

// A second click within 4 s confirms
ListButton {
    id: root

    property string idleText: ""
    property string confirmText: "Click again"
    property bool _armed: false

    signal confirmed

    listRow: root.idleText
    text: root._armed ? root.confirmText : root.idleText

    onClicked: {
        if (root._armed) {
            root._armed = false
            timeout.stop()
            root.confirmed()
        } else {
            root._armed = true
            timeout.restart()
        }
    }

    Timer {
        id: timeout

        interval: 4000
        onTriggered: root._armed = false
    }
}
