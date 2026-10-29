import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.common
import qs.settings.components
import qs.settings.data
import qs.settings

// Checks Lecer69/dots-hyprland for new commits when asked, and lists them.
// Update does what install.sh's update does (scripts/dots-update.sh). The
// page scrolls; the Update button stays in view below it
Item {
    id: root

    // What SettingsPanel's PgUp/PgDn scroll, as on the other pages
    readonly property Item contentItem: scroll.contentItem

    // The settings' StackLayout sizes itself from its pages' implicit size
    implicitWidth: scroll.implicitWidth
    implicitHeight: scroll.implicitHeight + footer.height

    readonly property string repo: "Lecer69/dots-hyprland"
    readonly property string webUrl: "https://github.com/" + repo
    // The clone dots-check.py fetches and dots-update.sh installs from
    readonly property string clone: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/lis/dots-hyprland"

    // dots-check.py's last result; null until a check works
    property var info: null
    property string checkError: ""
    // Unix seconds
    property real checkedAt: 0
    property real now: Date.now() / 1000
    readonly property bool checking: checker.running

    // The update's steps by dots-update.sh's names, how many are done, and
    // the one running
    property var steps: []
    property int stepsDone: 0
    property string currentStep: ""
    property bool updating: false
    // The update went through and a detached script is restarting the shell
    property bool restarting: false
    property bool confirming: false
    property string status: ""

    readonly property var latest: info?.latest ?? null
    readonly property var installed: info?.installed ?? null
    readonly property int behind: info?.behind ?? 0
    readonly property var commits: info?.commits ?? []
    // Something an update would change
    readonly property bool outdated: info !== null && (installed === null || behind > 0 || installed.differs > 0)
    // An update would delete a git checkout of the shell
    readonly property bool blocked: (info?.devCheckout ?? "") !== "" && SettingsData.s.dotsUpdater.updateShell

    readonly property string headline: restarting ? "Restarting…"
        : updating ? "Updating…"
        : checking ? "Checking…"
        : checkError !== "" ? "Couldn't check for updates"
        : info === null ? "Not checked yet"
        : installed === null ? "Unknown version"
        : behind > 0 ? behind + (behind === 1 ? " new commit" : " new commits")
        : "Up to date"

    // A pending "click again" is for what the button said then
    onInfoChanged: {
        root.confirming = false
        confirmTimeout.stop()
    }

    readonly property bool open: visible && (QsWindow.window?.visible ?? false)

    // "just now", "5 min ago", "3 h ago", "yesterday", "12 days ago", "Mar 4, 2026"
    function ago(seconds) {
        const s = Math.max(0, root.now - seconds)
        if (s < 60)
            return "just now"
        if (s < 3600)
            return Math.floor(s / 60) + " min ago"
        if (s < 86400)
            return Math.floor(s / 3600) + " h ago"
        const days = Math.floor(s / 86400)
        if (days < 30)
            return days === 1 ? "yesterday" : days + " days ago"
        return new Date(seconds * 1000).toLocaleDateString(Qt.locale(), "MMM d, yyyy")
    }

    function stepLabel(name) {
        switch (name) {
        case "checkout": return "Getting " + (root.latest?.short ?? "the commit")
        case "backup": return "Backing up"
        case "hypr": return "Updating the Hyprland config"
        case "command": return "Installing the lis command"
        case "shell": return "Copying the new shell"
        case "reload": return "Reloading Hyprland"
        }
        return "Starting"
    }

    function check() {
        if (checker.running || root.updating || root.restarting)
            return
        root.checkError = ""
        checker.running = true
    }

    function update() {
        const shell = SettingsData.s.dotsUpdater.updateShell
        const backup = SettingsData.s.dotsUpdater.backup
        root.status = ""
        root.steps = ["checkout"].concat(backup ? ["backup"] : [], ["hypr", "command", shell ? "shell" : "reload"])
        root.stepsDone = 0
        root.currentStep = ""
        root.updating = true
        updater.restarts = shell
        updater.target = root.latest.short
        updater.failure = ""
        updater.backupPath = ""
        updater.command = ["bash", Quickshell.shellPath("scripts/dots-update.sh"), root.clone, root.latest.sha, backup ? "1" : "0", shell ? "1" : "0"]
        updater.running = true
    }

    Timer {
        interval: 30000
        repeat: true
        running: root.open
        triggeredOnStart: true
        onTriggered: root.now = Date.now() / 1000
    }

    Process {
        id: checker
        command: ["python3", Quickshell.shellPath("scripts/dots-check.py"), root.clone, root.webUrl + ".git"]

        stdout: StdioCollector {
            onStreamFinished: {
                let result = null
                try {
                    result = JSON.parse(text)
                } catch (e) {
                    console.warn("[DotsUpdater] unreadable check output:", e)
                }
                root.now = Date.now() / 1000
                if (result === null || result.error) {
                    root.checkError = result?.error ?? "The check failed"
                    return
                }
                root.info = result
                root.checkedAt = root.now
            }
        }

        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("[DotsUpdater]", text.trim())
        }
    }

    // dots-update.sh prints "step <name>", then "done <name> [detail]" or
    // "fail <name> <reason>"
    Process {
        id: updater

        property bool restarts: false
        property string target: ""
        property string failure: ""
        property string backupPath: ""

        stdout: SplitParser {
            onRead: line => {
                const parts = line.split(" ")
                const detail = parts.slice(2).join(" ")
                if (parts[0] === "step") {
                    root.currentStep = parts[1]
                } else if (parts[0] === "done") {
                    root.stepsDone++
                    if (parts[1] === "backup" && detail.endsWith(".zip"))
                        updater.backupPath = detail
                } else if (parts[0] === "fail") {
                    updater.failure = root.stepLabel(parts[1]) + " failed: " + detail
                }
            }
        }

        stderr: StdioCollector {
            id: updateErrors
        }

        onExited: code => {
            root.updating = false
            root.currentStep = ""
            if (code !== 0 && updateErrors.text.trim() !== "")
                console.warn("[DotsUpdater]", updateErrors.text.trim())

            const backup = updater.backupPath !== "" ? "Backup in " + updater.backupPath : ""
            if (code === 0 && updater.restarts) {
                // Until this shell is stopped
                root.restarting = true
                root.status = backup
                restartTimeout.start()
                return
            }
            if (code === 0)
                root.status = "Updated to " + updater.target + (backup !== "" ? " · " + backup : "")
            else
                root.status = updater.failure || "The update failed"
            root.check()
        }
    }

    Timer {
        id: restartTimeout
        interval: 20000
        onTriggered: {
            root.restarting = false
            root.status = "The shell didn't restart, see ~/.cache/lis/dots-update.log"
        }
    }

    Timer {
        id: confirmTimeout
        interval: 4000
        onTriggered: root.confirming = false
    }

    ScrollView {
        id: scroll
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: footer.top }
        clip: true
        contentWidth: availableWidth

        ColumnLayout {
            width: scroll.availableWidth
            spacing: 0

            // Clear of the settings' ✕
            Item { Layout.preferredHeight: 24 }

            RowLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 16
                Layout.rightMargin: 16
                spacing: 16

                ColumnLayout {
                    spacing: 3
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0

                    Text {
                        text: root.headline
                        font { pixelSize: 15; weight: Font.DemiBold }
                        color: "#ffffff"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: root.checkError !== "" ? root.checkError
                            : "github.com/" + root.repo + (root.checkedAt > 0 ? " · checked " + root.ago(root.checkedAt) : "")
                        textFormat: Text.PlainText
                        font.pixelSize: 12
                        color: "#6b6b6b"
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                PanelButton {
                    text: root.checking ? "Checking…" : "Check for Updates"
                    enabled: !root.checking && !root.updating && !root.restarting
                    Layout.alignment: Qt.AlignVCenter
                    onClicked: root.check()
                }
            }

            Item {
                visible: root.info !== null
                Layout.preferredHeight: 16
            }
            SectionHeader {
                visible: root.info !== null
                title: "Version"
            }

            SettingRow {
                visible: root.info !== null
                label: "Installed"
                description: root.installed === null ? "The installed files don't match a commit"
                    : (root.installed.differs > 0 ? root.installed.differs + (root.installed.differs === 1 ? " file" : " files") + " edited locally · " : "")
                        + root.ago(root.installed.time) + " · " + root.installed.subject
                CommitLink {
                    sha: root.installed?.sha ?? ""
                    webUrl: root.webUrl
                }
            }
            SettingRow {
                visible: root.info !== null
                label: "Latest"
                description: root.latest !== null ? root.ago(root.latest.time) + " · " + root.latest.subject : ""
                CommitLink {
                    sha: root.latest?.sha ?? ""
                    webUrl: root.webUrl
                }
            }

            Item {
                visible: root.commits.length > 0
                Layout.preferredHeight: 16
            }
            SectionHeader {
                visible: root.commits.length > 0
                title: root.installed !== null && root.behind > 0
                    ? "New Commits" + (root.behind > root.commits.length ? " · newest " + root.commits.length + " of " + root.behind : "")
                    : "Recent Commits"
            }

            Repeater {
                model: root.commits

                CommitRow {
                    required property var modelData

                    commit: modelData
                    webUrl: root.webUrl
                    age: root.ago(modelData.time)
                }
            }

            Item { Layout.preferredHeight: 16 }
            SectionHeader { title: "Update" }

            SettingRow {
                label: "Back Up First"
                description: "Zips hypr and quickshell into ~/.dots-hyprland-backups"
                ToggleSwitch {
                    enabled: !root.updating
                    checked: SettingsData.s.dotsUpdater.backup
                    onToggled: v => SettingsData.s.dotsUpdater.backup = v
                }
            }
            SettingRow {
                label: "Update Shell"
                description: "Replaces ~/.config/quickshell and restarts the shell"
                ToggleSwitch {
                    enabled: !root.updating
                    checked: SettingsData.s.dotsUpdater.updateShell
                    onToggled: v => SettingsData.s.dotsUpdater.updateShell = v
                }
            }
            SettingRow {
                label: "Kept As-Is"
                description: "hypr/custom, hyprpaper.conf, monitors.conf, monitors.lua, workspaces.conf"
            }

            Item { Layout.preferredHeight: 16 }
        }
    }

    Item {
        id: footer

        readonly property bool shown: root.outdated || root.updating || root.restarting || root.status !== ""

        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: shown ? footerColumn.implicitHeight + 25 : 0
        visible: shown

        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right; leftMargin: 16; rightMargin: 16 }
            height: 1
            color: "#262626"

            // How far the update is
            Rectangle {
                visible: root.updating || root.restarting
                height: 1
                width: parent.width * (root.restarting ? 1 : root.stepsDone / Math.max(1, root.steps.length))
                color: "#e6e6e6"

                Behavior on width {
                    NumberAnimation { duration: 250; easing.type: Easing.OutCubic }
                }
            }
        }

        Column {
            id: footerColumn
            anchors { horizontalCenter: parent.horizontalCenter; verticalCenter: parent.verticalCenter; verticalCenterOffset: 0.5 }
            spacing: 6

            // The first click asks; a second one within 4 s updates
            Rectangle {
                id: updateButton

                readonly property bool usable: root.outdated && !root.blocked && !root.checking && !root.updating && !root.restarting
                readonly property string verb: root.installed === null ? "Install" : root.behind > 0 ? "Update to" : "Reinstall"

                anchors.horizontalCenter: parent.horizontalCenter
                height: 28
                width: updateLabel.implicitWidth + 24
                radius: 6
                opacity: usable || root.updating || root.restarting ? 1 : 0.4
                color: !usable ? "#1f1f1f"
                     : updateArea.pressed ? "#333333"
                     : updateArea.containsMouse ? "#2a2a2a"
                     : "#1f1f1f"

                Text {
                    id: updateLabel
                    anchors.centerIn: parent
                    text: root.restarting ? "Restarting the shell…"
                        : root.updating ? root.stepLabel(root.currentStep) + "…"
                        : !root.outdated ? "Up to date"
                        : root.confirming ? "Click again to " + updateButton.verb.split(" ")[0].toLowerCase()
                        : updateButton.verb + " " + (root.latest?.short ?? "")
                    font { pixelSize: 12; weight: Font.Medium }
                    color: "#e6e6e6"
                }

                MouseArea {
                    id: updateArea
                    anchors.fill: parent
                    enabled: updateButton.usable
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (!root.confirming) {
                            root.confirming = true
                            confirmTimeout.restart()
                            return
                        }
                        root.confirming = false
                        confirmTimeout.stop()
                        root.update()
                    }
                }
            }

            Text {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: text !== ""
                text: root.blocked && !root.updating && !root.restarting
                    ? root.info.devCheckout + " is a git checkout · turn off Update Shell to update the rest"
                    : root.status
                textFormat: Text.PlainText
                font.pixelSize: 12
                color: "#6b6b6b"
            }
        }
    }
}
