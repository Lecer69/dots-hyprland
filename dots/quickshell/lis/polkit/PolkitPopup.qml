pragma ComponentBehavior: Bound

import Quickshell
import Quickshell.Services.Polkit
import QtQuick

Item {
    id: root

    PolkitAgent {
        id: agent
    }

    PolkitDialog {
        agent: agent
    }
}
