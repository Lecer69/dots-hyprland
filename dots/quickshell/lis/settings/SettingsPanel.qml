import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.components
import qs.settings.data
import qs.settings.pages

Rectangle {
    id: root
    signal closeRequested

    radius: 12
    color: "#0f0f0f"
    clip: true
    border.color: "#1f1f1f"
    border.width: 1

    // PgUp / PgDn scroll the open page by most of a screen
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

        // Sidebar
        ColumnLayout {
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
                model: ["General", "Bar", "Lock", "Idle", "osu!", "Cleanup", "Dots Updater"]

                NavItem {
                    required property string modelData
                    required property int index

                    Layout.fillWidth: true
                    label: modelData
                    active: pager.currentIndex === index
                    onClicked: pager.currentIndex = index
                }
            }

            Item { Layout.fillHeight: true }
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
