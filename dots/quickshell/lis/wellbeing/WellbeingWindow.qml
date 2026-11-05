import qs.common

PanelHost {
    id: root

    name: "wellbeing"
    description: "Toggles the Digital Wellbeing panel"

    property bool locked: false

    readonly property WellbeingState tracker: WellbeingState {
        locked: root.locked
    }

    UsagePanel {
        anchors.centerIn: parent
        width: 500
        height: 610
        visible: root.panelShown
        tracker: root.tracker
        title: "Wellbeing"
        currentLabel: "Now: "
        onCloseRequested: root.close()
    }
}
