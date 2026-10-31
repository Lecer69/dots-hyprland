import QtQuick
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import qs.settings.data
import qs.common

Rectangle {
    id: root
    width: 400
    height: content.implicitHeight + 24
    radius: 12
    color: Theme.panel
    border.color: Theme.border
    border.width: 1

    signal dismissed

    // Null once closed
    property var notification
    property int timeout: (root.notification && root.notification.expireTimeout > 0) ? root.notification.expireTimeout : (SettingsData.s.general.notificationTimeout * 1000)

    // "default" is the card click, not a button
    readonly property var defaultAction: (root.notification?.actions ?? []).find(a => a.identifier === "default") ?? null
    readonly property var buttonActions: (root.notification?.actions ?? []).filter(a => a.identifier !== "default")

    property bool _removed: false
    function _remove() {
        if (root._removed) return
        root._removed = true
        root.dismissed()
    }

    // Covers closes by the app
    Connections {
        target: root.notification
        function onClosed() { root._remove() }
    }

    // Closing destroys this card before returning, so touch nothing after
    function _close(expired) {
        const notification = root.notification
        if (!notification) root._remove()
        else if (expired) notification.expire()
        else notification.dismiss()
    }

    function _invoke(action) {
        // invoke() closes it unless it's resident
        const resident = root.notification?.resident ?? false
        action.invoke()
        if (resident) dismissTimer.restart()
    }

    Timer {
        id: dismissTimer
        interval: root.timeout
        running: true
        onTriggered: root._close(true)
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: root.defaultAction ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (root.defaultAction) root._invoke(root.defaultAction)
        onContainsMouseChanged: {
            if (containsMouse) {
                dismissTimer.stop()
            } else {
                dismissTimer.restart()
            }
        }
    }

    ColumnLayout {
        id: content
        anchors {
            left: parent.left
            right: parent.right
            top: parent.top
            margins: 12
        }
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Item {
                Layout.preferredWidth: 44
                Layout.preferredHeight: 44
                // The text can be two lines
                Layout.alignment: Qt.AlignVCenter
                visible: iconImage.status === Image.Ready || hintImage.status === Image.Ready

                Image {
                    id: hintImage
                    anchors.fill: parent
                    source: root.notification?.image ?? ""
                    fillMode: Image.PreserveAspectCrop
                    visible: status === Image.Ready

                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: Rectangle {
                            width: hintImage.width
                            height: hintImage.height
                            radius: 8
                        }
                    }
                }

                Image {
                    id: iconImage
                    anchors.fill: parent
                    visible: hintImage.status !== Image.Ready
                    source: {
                        const icon = root.notification?.appIcon
                        if (!icon || icon === "") return ""
                        if (icon.startsWith("/") || icon.startsWith("file://")) return icon
                        return "image://icon/" + icon
                    }
                    sourceSize.width: 88
                    sourceSize.height: 88
                    fillMode: Image.PreserveAspectFit
                    onStatusChanged: {
                        if (status === Image.Error)
                            console.log("[Notifications] Icon failed:", source)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 3

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Text {
                        id: appLabel
                        text: root.notification?.appName ?? ""
                        visible: text !== ""
                        color: Theme.adapt("#808080")
                        font.pixelSize: 12
                        Layout.maximumWidth: 120
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    Text {
                        visible: appLabel.visible && summaryLabel.visible
                        text: "·"
                        color: Theme.adapt("#4a4a4a")
                        font.pixelSize: 12
                    }

                    Text {
                        id: summaryLabel
                        text: root.notification?.summary ?? ""
                        visible: text !== ""
                        color: Theme.text
                        font.pixelSize: 13
                        font.weight: Font.Medium
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        maximumLineCount: 1
                        textFormat: Text.PlainText
                    }
                }

                Text {
                    property string cleaned: (root.notification?.body ?? "")
                        .replace(/<img[^>]*>/gi, "")
                        .replace(/<[^>]*>/g, "")
                        .trim()

                    text: cleaned
                    visible: cleaned !== ""
                    color: Theme.adapt("#999999")
                    font.pixelSize: 12
                    Layout.fillWidth: true
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    textFormat: Text.PlainText
                }
            }

            Item {
                Layout.preferredWidth: 22
                Layout.preferredHeight: 22
                Layout.alignment: Qt.AlignTop

                Text {
                    anchors.centerIn: parent
                    text: "✕"
                    color: closeHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")
                    font.pixelSize: 12
                }

                MouseArea {
                    id: closeHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root._close(false)
                }
            }
        }

        // Only cards with actions
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            visible: root.buttonActions.length > 0

            Repeater {
                model: root.buttonActions.slice(0, 3)
                delegate: Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 1
                    Layout.horizontalStretchFactor: 1
                    implicitHeight: 28
                    radius: 6
                    color: actionHover.pressed ? Theme.adapt("#333333") : actionHover.containsMouse ? Theme.adapt("#2a2a2a") : Theme.border

                    Text {
                        anchors.centerIn: parent
                        width: parent.width - 16
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData.text
                        color: Theme.text
                        font.pixelSize: 12
                        font.weight: Font.Medium
                        elide: Text.ElideRight
                        textFormat: Text.PlainText
                    }

                    MouseArea {
                        id: actionHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root._invoke(modelData)
                    }
                }
            }
        }
    }

    NumberAnimation on opacity {
        running: true
        from: 0
        to: 1
        duration: 150
    }
}