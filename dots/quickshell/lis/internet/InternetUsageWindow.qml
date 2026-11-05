import qs.common

PanelHost {
    id: root

    name: "internetusage"
    description: "Toggles the Internet Usage panel"

    readonly property InternetUsageState tracker: InternetUsageState {}

    UsagePanel {
        anchors.centerIn: parent
        width: 500
        height: 610
        visible: root.panelShown
        tracker: root.tracker
        title: "Internet Usage"
        currentLabel: "Latest: "
        onCloseRequested: root.close()
    }
}
