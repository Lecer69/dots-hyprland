pragma Singleton
import QtQuick

// Up/Down between rows marked `listRow`; stops at the list's ends
QtObject {
    function step(item: Item, forward: bool, list: var): bool {
        const group = list ?? item.listRow
        const y = item.mapToItem(null, 0, 0).y
        let next = item.nextItemInFocusChain(forward)
        for (let i = 0; next && next !== item && i < 1000; i++) {
            if (next.listRow !== undefined && next.listRow === group) {
                // Tab order wraps around; a list doesn't
                const nextY = next.mapToItem(null, 0, 0).y
                if (list === undefined && (forward ? nextY < y : nextY > y))
                    return false
                next.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason)
                return true
            }
            next = next.nextItemInFocusChain(forward)
        }
        return false
    }

    // ListView rows aren't in Tab order, so by index
    function stepView(view: ListView, index: int, forward: bool): bool {
        const next = index + (forward ? 1 : -1)
        if (next < 0 || next >= view.count)
            return false
        view.positionViewAtIndex(next, ListView.Contain)
        const row = view.itemAtIndex(next)
        if (!row)
            return false
        row.forceActiveFocus(forward ? Qt.TabFocusReason : Qt.BacktabFocusReason)
        return true
    }
}
