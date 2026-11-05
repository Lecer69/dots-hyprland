pragma Singleton

import QtQuick
import Quickshell

// One BrightnessDevice per screen, so the hover bars and the Displays panel share a level
Singleton {
    id: root

    property var _devices: ({})

    function device(screenName: string): var {
        if (!screenName) return null
        if (!root._devices[screenName])
            root._devices[screenName] = deviceComponent.createObject(root, { screenName: screenName })
        return root._devices[screenName]
    }

    Component {
        id: deviceComponent

        BrightnessDevice {}
    }
}
