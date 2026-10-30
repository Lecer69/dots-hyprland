import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.components
import qs.settings.data
import qs.settings.pages

Rectangle {
    id: root
    // Up/Down switch pages from here
    readonly property Item initialFocus: nav
    signal closeRequested

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    // PgUp / PgDn scroll the page by most of a screen
    function scrollPage(direction) {
        const flick = pager.children[pager.currentIndex].contentItem
        const from = pageScroll.running ? pageScroll.to : flick.contentY
        const maxY = Math.max(0, flick.contentHeight - flick.height)
        pageScroll.stop()
        pageScroll.target = flick
        pageScroll.to = Math.max(0, Math.min(maxY, from + direction * flick.height * 0.9))
        pageScroll.start()
    }

    NumberAnimation {
        id: pageScroll
        property: "contentY"
        duration: 160
        easing.type: Easing.OutCubic
    }

    Shortcut {
        sequences: ["PgUp"]
        onActivated: root.scrollPage(-1)
    }

    Shortcut {
        sequences: ["PgDown"]
        onActivated: root.scrollPage(1)
    }

    RowLayout {
        anchors { fill: parent; margins: 12 }
        spacing: 6

        ColumnLayout {
            id: nav

            // Pager order; the bottom pages follow the top ones
            readonly property var topPages: ["General", "Bar", "Lock", "Idle", "osu!"]
            readonly property var bottomPages: ["Cleanup", "Dots Updater"]

            function shift(direction: int): void {
                const count = nav.topPages.length + nav.bottomPages.length
                pager.currentIndex = (pager.currentIndex + direction + count) % count
            }

            activeFocusOnTab: true
            Keys.onUpPressed: nav.shift(-1)
            Keys.onDownPressed: nav.shift(1)

            Layout.preferredWidth: 160
            Layout.fillHeight: true
            spacing: 2

            Text {
                text: "Settings"
                font { pixelSize: 15; weight: Font.DemiBold }
                color: "#ffffff"
                Layout.leftMargin: 10
                Layout.topMargin: 8
                Layout.bottomMargin: 16
            }

            Repeater {
                model: nav.topPages

                NavItem {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    label: modelData
                    active: pager.currentIndex === index
                    focused: nav.activeFocus
                    onClicked: pager.currentIndex = index
                }
            }

            Item { Layout.fillHeight: true }

            Repeater {
                model: nav.bottomPages

                NavItem {
                    required property string modelData
                    required property int index
                    readonly property int page: nav.topPages.length + index

                    Layout.fillWidth: true
                    label: modelData
                    active: pager.currentIndex === page
                    focused: nav.activeFocus
                    onClicked: pager.currentIndex = page
                }
            }
        }

        Rectangle {
            Layout.preferredWidth: 1
            Layout.preferredHeight: parent.height * 0.75
            Layout.alignment: Qt.AlignVCenter
            color: "#262626"
        }

        StackLayout {
            id: pager
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: 0

            GeneralPage {}
            BarPage {}
            LockPage {}
            IdlePage {}
            OsuPage {}
            CleanupPage {}
            DotsUpdaterPage {}
        }
    }

    Text {
        anchors { top: parent.top; right: parent.right; topMargin: 22; rightMargin: 28 }
        text: "✕"
        font.pixelSize: 12
        color: closeArea.containsMouse ? "#dddddd" : "#666666"

        MouseArea {
            id: closeArea
            anchors { fill: parent; margins: -6 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
        }
    }
}
