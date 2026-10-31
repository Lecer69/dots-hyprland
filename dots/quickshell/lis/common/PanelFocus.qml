pragma Singleton
import QtQuick

// The most recently opened panel on a screen holds the keyboard, and gets it back when the one above closes
QtObject {
    property var stack: []

    function topOn(screenName: string): var {
        for (let i = stack.length - 1; i >= 0; i--) {
            if (stack[i].screenName === screenName)
                return stack[i]
        }
        return null
    }

    function opened(panel): void {
        stack = stack.filter(p => p !== panel).concat([panel])
    }

    function closed(panel): void {
        if (stack.includes(panel)) stack = stack.filter(p => p !== panel)
    }
}
