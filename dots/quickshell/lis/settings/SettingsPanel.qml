import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import qs.settings.components
import qs.settings.data
import qs.settings.pages
import qs.common

Rectangle {
    id: root
    // Up/Down switch pages from here
    readonly property Item initialFocus: nav
    property bool shown: false
    signal closeRequested

    onShownChanged: {
        if (!root.shown)
            search.text = ""
    }

    // Empties the search, with the keyboard back on the pages
    function cancelSearch(): void {
        nav.forceActiveFocus()
        search.text = ""
    }

    // Focusing a row's control lights it and brings it into view
    function openResult(page: int, row: Item): void {
        pager.currentIndex = page
        search.text = ""
        nav.forceActiveFocus()
        jump.row = row
        jump.restart()
    }

    Timer {
        id: jump

        property Item row: null

        // The page is laid out by then
        interval: 30
        onTriggered: {
            const control = jump.row?.activeFocusOnTab ? jump.row : jump.row?.nextItemInFocusChain(true)
            let parent = control
            for (let i = 0; parent && parent !== jump.row && i < 100; i++)
                parent = parent.parent
            if (parent === jump.row)
                control.forceActiveFocus(Qt.TabFocusReason)
        }
    }

    Shortcut {
        sequences: ["Ctrl+F"]
        onActivated: search.forceActiveFocus()
    }

    radius: 12
    color: Theme.panel
    clip: true
    border.color: Theme.border
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
            readonly property var topPages: ["System", "General", "Bar", "Lock", "Idle", "Devices", "Phone Sync", "osu!"]
            readonly property var bottomPages: ["Storage", "Dots Updater"]

            function shift(direction: int): void {
                const count = nav.topPages.length + nav.bottomPages.length
                pager.currentIndex = (pager.currentIndex + direction + count) % count
            }

            activeFocusOnTab: true
            Keys.onUpPressed: nav.shift(-1)
            Keys.onDownPressed: nav.shift(1)
            // Typing starts a search
            Keys.onPressed: event => {
                if (event.text.trim() !== "" && !(event.modifiers & (Qt.ControlModifier | Qt.AltModifier | Qt.MetaModifier))) {
                    search.text += event.text
                    search.forceActiveFocus()
                    event.accepted = true
                }
            }

            Layout.preferredWidth: 160
            Layout.fillWidth: false
            Layout.fillHeight: true
            spacing: 2

            Text {
                text: "Settings"
                font { pixelSize: 15; weight: Font.DemiBold }
                color: Theme.adapt("#ffffff")
                Layout.leftMargin: 10
                Layout.topMargin: 8
                Layout.bottomMargin: 14
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.bottomMargin: 12
                implicitHeight: 32
                radius: 6
                color: Theme.hover

                TextInput {
                    id: search

                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    selectionColor: Theme.adapt("#333333")
                    selectedTextColor: Theme.adapt("#ffffff")
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    activeFocusOnTab: true

                    // Escape empties it first, then closes the panel
                    Keys.onShortcutOverride: event => event.accepted = event.key === Qt.Key_Escape && search.text !== ""
                    Keys.onEscapePressed: root.cancelSearch()
                    Keys.onDownPressed: results.searching ? results.focusFirst() : nav.forceActiveFocus()
                    Keys.onReturnPressed: results.chooseFirst()
                    Keys.onEnterPressed: results.chooseFirst()

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: search.text.length === 0
                        text: "Search"
                        color: Theme.textDim
                        font.pixelSize: 13
                    }
                }
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
            color: Theme.adapt("#262626")
        }

        StackLayout {
            id: pager
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !results.searching
            currentIndex: 0

            SystemPage {}
            GeneralPage {}
            BarPage {}
            LockPage {}
            IdlePage {}
            DevicesPage {}
            PhonePage {}
            OsuPage {}
            StoragePage {}
            DotsUpdaterPage {}
        }

        SearchResults {
            id: results

            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: results.searching
            pager: pager
            pageNames: nav.topPages.concat(nav.bottomPages)
            query: search.text
            onChosen: (page, row) => root.openResult(page, row)
            onCancelled: {
                search.forceActiveFocus()
                search.text = ""
            }
        }
    }

    Text {
        anchors { top: parent.top; right: parent.right; topMargin: 22; rightMargin: 28 }
        text: "✕"
        font.pixelSize: 12
        color: closeArea.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")

        MouseArea {
            id: closeArea
            anchors { fill: parent; margins: -6 }
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: root.closeRequested()
        }
    }
}
