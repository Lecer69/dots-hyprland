import QtQuick
import qs.common

// In a column of rows: Up and Down go to the button with the same text
PanelButton {
    id: root

    property string listRow: root.text
    // Where Up goes from the first row
    property Item above: null

    Keys.onUpPressed: {
        if (!KeyNav.step(root, false))
            root.above?.forceActiveFocus()
    }
    Keys.onDownPressed: KeyNav.step(root, true)
}
