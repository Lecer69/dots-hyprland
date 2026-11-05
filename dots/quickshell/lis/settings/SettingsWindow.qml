import QtQuick
import qs.common
import qs.settings.data

PanelHost {
    id: root

    name: "settings"
    description: "Opens settings"
    // While a file chooser is open
    hidden: ConfigTransfer.picking

    property var _target: null
    property bool _indexing: false

    // Opens on a setting the launcher found
    function openSetting(page: int, label: string): void {
        root._target = { page: page, label: label };
        if (root.panelShown)
            root._openTarget();
        else
            root.shown = true;
    }

    function _openTarget(): void {
        root.item.openSetting(root._target.page, root._target.label);
        root._target = null;
    }

    function _finishIndex(): void {
        SettingsIndex.remember(root.item.rows());
        root._indexing = false;
        root.release();
    }

    onPanelShownChanged: {
        if (root.panelShown && root._target)
            root._openTarget();
        // Rows come and go with what was set
        else if (!root.panelShown && root.item)
            SettingsIndex.remember(root.item.rows());
    }

    // Built once for the launcher to search; read a moment later, as some rows wait for their data
    readonly property Timer indexTimer: Timer {
        interval: 5000
        running: true
        onTriggered: {
            if (root._indexing) {
                root._finishIndex();
            } else if (!root.item) {
                root._indexing = true;
                root.build();
                interval = 2000;
                restart();
            }
        }
    }

    SettingsPanel {
        anchors.centerIn: parent
        width: 780
        height: 560
        shown: root.panelShown
        onCloseRequested: root.close()

        layer.enabled: true
        layer.effect: null
    }
}
