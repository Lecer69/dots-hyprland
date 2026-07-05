pragma Singleton
import QtQuick

QtObject {
    id: root

    property ListModel model: ListModel {}

    function add(entry): void {
        root.model.insert(0, entry)
    }

    function removeAt(index: int): void {
        root.model.remove(index)
    }

    function clear(): void {
        root.model.clear()
    }
}
