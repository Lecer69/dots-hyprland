import qs.common

PanelHost {
    id: root

    name: "gamma"
    description: "Toggles the color settings panel"

    // Made at startup, so a night light left on comes back
    readonly property var service: GammaService

    GammaPanel {
        anchors.centerIn: parent
        width: implicitWidth
        height: Math.min(implicitHeight, parent.height - 80)
        onCloseRequested: root.close()
    }
}
