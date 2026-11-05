import qs.common

PanelHost {
    id: root

    name: "notificationCenter"
    description: "Toggles the notification center panel"

    onPanelShownChanged: if (panelShown) item.showNewest()

    NotificationCenterPanel {
        anchors.centerIn: parent
        width: 460
        height: 580
        onCloseRequested: root.close()
    }
}
