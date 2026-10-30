pragma Singleton
import QtQuick

// The most recently opened panel holds the keyboard, and gets it back when the one above closes
QtObject {
    property var stack: []
    readonly property var top: stack.length > 0 ? stack[stack.length - 1] : null

    function opened(panel): void {
        stack = stack.filter(p => p !== panel).concat([panel])
    }

    function closed(panel): void {
        if (stack.includes(panel)) stack = stack.filter(p => p !== panel)
    }
}
