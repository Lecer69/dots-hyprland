pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.settings.data

QtObject {
    id: root

    property ListModel model: ListModel {}

    // Older entries drop off past this
    readonly property int maxEntries: 100
    // Only two lines ever show
    readonly property int maxBody: 1000
    readonly property bool keep: SettingsData.s.general.keepNotificationHistory

    property bool _loaded: false

    function add(entry): void {
        entry.body = (entry.body ?? "").slice(0, root.maxBody)
        root.model.insert(0, entry)
        if (root.model.count > root.maxEntries)
            root.model.remove(root.maxEntries, root.model.count - root.maxEntries)
        Qt.callLater(root._save)
    }

    function removeAt(index: int): void {
        root.model.remove(index)
        Qt.callLater(root._save)
    }

    function clear(): void {
        root.model.clear()
        Qt.callLater(root._save)
    }

    function _save(): void {
        // Never overwrite a file that hasn't been read
        if (!root.keep || !root._loaded) return

        const saved = []
        for (let i = 0; i < root.model.count; i++) {
            const e = root.model.get(i)
            if (e.transient) continue
            saved.push({
                appName: e.appName,
                summary: e.summary,
                body: e.body,
                appIcon: e.appIcon,
                image: e.image,
                timestamp: e.timestamp
            })
        }
        root._store.setText(JSON.stringify(saved))
    }

    function _load(text: string): void {
        try {
            const saved = JSON.parse(text)
            if (root.keep && Array.isArray(saved)) {
                // Behind anything that arrived while reading
                for (const e of saved.slice(0, root.maxEntries - root.model.count))
                    root.model.append(Object.assign({ transient: false }, e))
            }
        } catch (e) {
            console.warn("[notifications] can't parse the saved history:", e)
        }
        root._loaded = true
    }

    // Turning it off takes the text off the disk too
    onKeepChanged: {
        if (root.keep) root._save()
        else root._store.setText("[]")
    }

    // Not in ~/.config/lis, as that goes into .lisc exports
    property FileView _store: FileView {
        path: Quickshell.env("HOME") + "/.local/state/lis/notifications.json"
        blockWrites: true
        printErrors: false

        onLoaded: root._load(text())
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound) root._load("[]")
            else console.warn("[notifications] can't read the saved history:", FileViewError.toString(error))
        }
    }
}
