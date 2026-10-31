import QtQuick
import QtQuick.Layouts
import qs.common

// A commit; clicking it opens its message and files (ones an update doesn't install are dimmed)
Item {
    id: root

    // From dots-check.py
    property var commit: ({})
    property string webUrl: ""
    property string age: ""
    property bool expanded: false
    // The file list is made on first open
    property bool opened: false

    Layout.fillWidth: true
    implicitHeight: header.height + (expanded ? details.implicitHeight : 0)
    clip: true

    Behavior on implicitHeight {
        NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
    }

    // "+12 −3", zero parts left out
    function counts(added, removed) {
        const parts = []
        if (added > 0)
            parts.push("<font color='" + Theme.adapt("#a6e3a1") + "'>+" + added + "</font>")
        if (removed > 0)
            parts.push("<font color='" + Theme.adapt("#e06c6c") + "'>−" + removed + "</font>")
        return parts.join(" ")
    }

    Rectangle {
        id: header
        anchors { left: parent.left; right: parent.right; leftMargin: 8; rightMargin: 8 }
        height: 52
        radius: 6
        color: headerArea.containsMouse || header.activeFocus ? Theme.hover : "transparent"

        function toggle(): void {
            root.opened = true
            root.expanded = !root.expanded
        }

        activeFocusOnTab: true
        Keys.onSpacePressed: header.toggle()
        Keys.onReturnPressed: header.toggle()
        Keys.onEnterPressed: header.toggle()

        MouseArea {
            id: headerArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: header.toggle()
        }

        RowLayout {
            anchors { fill: parent; leftMargin: 8; rightMargin: 8 }
            spacing: 10

            Text {
                text: "›"
                font.pixelSize: 15
                color: Theme.textDim
                rotation: root.expanded ? 90 : 0
                Layout.preferredWidth: 8
                Layout.alignment: Qt.AlignVCenter
                horizontalAlignment: Text.AlignHCenter

                Behavior on rotation {
                    NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
                }
            }

            ColumnLayout {
                spacing: 2
                Layout.fillWidth: true
                Layout.minimumWidth: 0

                Text {
                    text: root.commit.subject ?? ""
                    textFormat: Text.PlainText
                    font.pixelSize: 13
                    color: Theme.text
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                Text {
                    readonly property int fileCount: root.commit.files?.length ?? 0

                    text: root.age + " · " + fileCount + (fileCount === 1 ? " file" : " files")
                        + "&nbsp;&nbsp;" + root.counts(root.commit.added, root.commit.removed)
                    textFormat: Text.StyledText
                    font.pixelSize: 12
                    color: Theme.textDim
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
            }

            CommitLink {
                sha: root.commit.sha ?? ""
                webUrl: root.webUrl
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }

    Loader {
        id: details
        anchors { top: header.bottom; left: parent.left; right: parent.right }
        active: root.opened

        sourceComponent: Component {
            ColumnLayout {
                spacing: 0

                Item { Layout.preferredHeight: 4 }

                Text {
                    visible: text !== ""
                    text: root.commit.body ?? ""
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.pixelSize: 12
                    color: Theme.adapt("#808080")
                    Layout.fillWidth: true
                    Layout.leftMargin: 34
                    Layout.rightMargin: 16
                    Layout.bottomMargin: 8
                }

                Repeater {
                    model: root.commit.files ?? []

                    RowLayout {
                        required property var modelData

                        spacing: 10
                        opacity: modelData.inScope ? 1 : 0.4
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        Layout.leftMargin: 34
                        Layout.rightMargin: 16

                        Text {
                            text: modelData.status
                            font.family: "JetBrainsMono Nerd Font"
                            font.pixelSize: 11
                            color: Theme.textDim
                            Layout.preferredWidth: 8
                        }
                        Text {
                            text: modelData.path
                            textFormat: Text.PlainText
                            font.pixelSize: 12
                            color: Theme.adapt("#b3b3b3")
                            elide: Text.ElideMiddle
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                        }
                        Text {
                            text: root.counts(modelData.added, modelData.removed)
                            textFormat: Text.StyledText
                            font.pixelSize: 11
                        }
                    }
                }

                Text {
                    visible: (root.commit.files ?? []).some(file => !file.inScope)
                    text: "Dimmed files aren't installed by an update"
                    font.pixelSize: 11
                    color: Theme.adapt("#4a4a4a")
                    Layout.leftMargin: 34
                    Layout.topMargin: 4
                }

                Item { Layout.preferredHeight: 12 }
            }
        }
    }
}
