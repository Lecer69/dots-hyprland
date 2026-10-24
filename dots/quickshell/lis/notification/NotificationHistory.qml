pragma Singleton
import QtQuick

QtObject {
    id: root

    property ListModel model: ListModel {}

    // Newest first; older entries drop off past this
    readonly property int maxEntries: 100

    function add(entry): void {
        root.model.insert(0, entry)
        if (root.model.count > root.maxEntries)
            root.model.remove(root.maxEntries, root.model.count - root.maxEntries)
    }

    function removeAt(index: int): void {
        root.model.remove(index)
    }

    function clear(): void {
        root.model.clear()
    }
}
