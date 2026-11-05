pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Covers the shell can't load itself: Qt goes direct, so a blocked host only times out
Singleton {
    id: root

    // Url -> local file url
    property var cached: ({})
    // Urls no proxy could get; these stay direct
    property var failed: ({})
    // The last cover needed a proxy, so the next ones skip the wait on the direct try
    property bool viaProxy: false

    property string _current: ""
    property string _next: ""

    function isRemote(url: string): bool {
        return /^https?:\/\//i.test(url);
    }

    // What an Image should load; empty while a fetch is on its way
    function sourceFor(url: string): string {
        if (root.cached[url])
            return root.cached[url];
        return root.viaProxy && root.isRemote(url) && !root.failed[url] ? "" : url;
    }

    function fetch(url: string): void {
        if (!root.isRemote(url) || root.cached[url] || root.failed[url] || url === root._current)
            return;
        if (fetcher.running) {
            root._next = url;
            return;
        }
        root._current = url;
        fetcher.command = ["sh", Quickshell.shellPath("scripts/fetch-via-proxy.sh"), url, root._fileFor(url)];
        fetcher.running = true;
    }

    function _fileFor(url: string): string {
        return Quickshell.cachePath("media-art/" + Qt.md5(url));
    }

    Process {
        id: fetcher

        onExited: code => {
            const url = root._current;
            root._current = "";
            if (code === 0) {
                root.cached = Object.assign({}, root.cached, { [url]: "file://" + root._fileFor(url) });
                root.viaProxy = true;
            } else {
                root.failed = Object.assign({}, root.failed, { [url]: true });
                root.viaProxy = false;
            }
            if (root._next !== "") {
                const next = root._next;
                root._next = "";
                root.fetch(next);
            }
        }
    }
}
