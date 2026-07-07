import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Notifications
import Quickshell.Wayland
import qs.settings.data

PanelWindow {
    id: root
    color: "transparent"
    anchors.bottom: true
    anchors.right: true

    visible: notifModel.count > 0
    implicitWidth: notifModel.count > 0 ? 450 : 0
    implicitHeight: notifModel.count > 0 ? notifColumn.implicitHeight + 16 : 0

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: notifModel.count > 0 ? 0 : -1

    property var focusedScreen: null
    screen: focusedScreen ?? Quickshell.screens[0]

    NotificationServer {
        id: server
        keepOnReload: true

        Component.onCompleted: console.log("[Notifications] Server registered on D-Bus")

        onNotification: (notif) => {
            console.log("[Notifications] Received:", notif.appName, "|", notif.summary, "|", notif.body)
            if (!NotificationState.notificationsEnabled) return

            if (SettingsData.s.osu.disableNotifications) {
                const focusedAppId = ToplevelManager.activeToplevel?.appId ?? ""
                if (focusedAppId === "osu!.exe" || focusedAppId === "osu!") return
            }

            if (notifModel.count === 0) {
                const focusedName = Hyprland.focusedMonitor?.name
                for (let i = 0; i < Quickshell.screens.length; i++) {
                    if (Quickshell.screens[i].name === focusedName) {
                        root.focusedScreen = Quickshell.screens[i]
                        break
                    }
                }
            }

            if (notifModel.count >= 8) {
                notifModel.remove(0)
            }

            const icon = notif.appIcon
            const iconSource = !icon || icon === "" ? ""
                : (icon.startsWith("/") || icon.startsWith("file://")) ? icon
                : "image://icon/" + icon

            NotificationHistory.add({
                appName: notif.appName,
                summary: notif.summary,
                body: notif.body,
                appIcon: iconSource,
                image: notif.image ?? "",
                time: Qt.formatTime(new Date(), "hh:mm"),
                defaultAction: () => notif.invokeAction("default")
            })

            notifModel.append({ notif: notif })
        }
    }

    ListModel {
        id: notifModel
        onCountChanged: {
            if (count === 0) root.focusedScreen = null
        }
    }

    Column {
        id: notifColumn
        anchors {
            bottom: parent.bottom
            right: parent.right
            margins: 10
        }
        spacing: 4
        property int count: notifModel.count

        Repeater {
            model: notifModel
            delegate: NotificationCard {
                notification: model.notif
                onDismissed: notifModel.remove(index)
            }
        }
    }
}
