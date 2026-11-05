import qs.common

PanelHost {
    id: root

    name: "calendar"
    description: "Toggles the calendar panel"
    closeOnClickOutside: true

    CalendarPanel {
        anchors.centerIn: parent
        width: 460
        height: 720
        onCloseRequested: root.close()
    }
}
