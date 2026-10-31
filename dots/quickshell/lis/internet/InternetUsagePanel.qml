import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.tools
import qs.common

Rectangle {
    id: root

    // 0 today, 1 this week
    property int viewMode: 0
    readonly property Item initialFocus: viewTabs
    property var weekDays: []
    property string selectedDayKey: ""
    property var _todaySorted: []
    property var _weekSorted: []
    property var _daySortedCache: ({})
    property var currentList: {
        if (viewMode === 0)
            return _todaySorted;

        if (selectedDayKey === "")
            return _weekSorted;

        return _daySortedCache[selectedDayKey] || [];
    }
    property real currentMax: currentList.length > 0 ? currentList[0].secs : 1
    property real totalMB: {
        var s = 0;
        for (var i = 0; i < currentList.length; i++) s += currentList[i].secs
        return s;
    }

    signal closeRequested()

    // Per-app colour and icon, so they aren't resolved every tick
    property var _enrichCache: ({})

    // Past either end: the whole week
    function stepDay(direction: int): void {
        const days = root.weekDays.filter(d => d.hasData === true)
        const i = days.findIndex(d => d.key === root.selectedDayKey)
        const next = i < 0 ? (direction > 0 ? 0 : days.length - 1) : i + direction
        root.selectedDayKey = next >= 0 && next < days.length ? days[next].key : ""
    }

    function _staticEnrich(name) {
        var c = root._enrichCache[name];
        if (c)
            return c;

        c = {
            "color": state.appColor(name),
            "iconName": root._guessIcon(name)
        };
        root._enrichCache[name] = c;
        return c;
    }

    function _enrich(arr) {
        var out = [];
        for (var i = 0; i < arr.length; i++) {
            var item = arr[i];
            var stat = root._staticEnrich(item.name);
            out.push({
                "name": item.name,
                "secs": item.secs,
                "color": stat.color,
                "timeLabel": state.formatData(item.secs),
                "isActive": item.name === state.activeApp,
                "iconName": stat.iconName
            });
        }
        return out;
    }

    property bool _todayDirty: true
    property bool _weekDirty: true
    property bool _daysDirty: true

    function _refreshDays() {
        if (!state._loaded)
            return ;

        root.weekDays = state.weekDays();
        var cache = {};
        for (var i = 0; i < root.weekDays.length; i++) {
            var key = root.weekDays[i].key;
            cache[key] = _enrich(state.sortedApps(state.dayTotals(key)));
        }
        root._daySortedCache = cache;
        root._daysDirty = false;
    }

    function _refresh() {
        if (!state._loaded)
            return ;

        if (root.viewMode === 0) {
            _todaySorted = _enrich(state.sortedApps(state.todayTotals()));
            _todayDirty = false;
            _weekDirty = true; // week totals include today
            _daysDirty = true;
        } else {
            _weekSorted = _enrich(state.sortedApps(state.weekTotals()));
            _weekDirty = false;
            _refreshDays();
        }
    }

    onViewModeChanged: {
        if (viewMode === 0 && _todayDirty)
            _refresh();
        else if (viewMode === 1) {
            selectedDayKey = "";
            if (_weekDirty || _daysDirty)
                _refresh();
        }
    }

    onVisibleChanged: {
        if (visible && state._loaded) {
            if (viewMode === 0 && _todayDirty)
                _refresh();
            else if (viewMode === 1 && (_weekDirty || _daysDirty))
                _refresh();
        }
    }

    function _guessIcon(appClass) {
        if (!appClass || appClass.length === 0)
            return "application-x-executable";

        // A throwing lookup would abort the refresh and empty the list
        try {
            return AppSearch.guessIcon(appClass);
        } catch (e) {
            console.warn("[InternetUsage] no icon for " + appClass + ":", e);
            return "application-x-executable";
        }
    }

    radius: 12
    color: Theme.panel
    clip: true
    border.color: Theme.border
    border.width: 1

    InternetUsageState {
        id: state
    }

    Connections {
        function onTriggered() {
            if (root.visible)
                root._refresh();
            else
                root._todayDirty = root._weekDirty = root._daysDirty = true; // rebuilt on next show
        }

        target: state._ticker
    }

    Connections {
        function on_LoadedChanged() {
            if (state._loaded)
                root._refresh();
        }

        target: state
    }

    Item {
        id: header

        width: parent.width
        height: 56

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Internet Usage"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: Theme.adapt("#ffffff")
        }

        Text {
            anchors.right: parent.right
            anchors.rightMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "✕"
            font.pixelSize: 12
            color: closeHover.containsMouse ? Theme.adapt("#dddddd") : Theme.adapt("#666666")

            MouseArea {
                id: closeHover

                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    ColumnLayout {
        anchors.top: header.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 8
        spacing: 14

        Row {
            id: viewTabs

            spacing: 4

            activeFocusOnTab: true
            Keys.onLeftPressed: root.viewMode = 0
            Keys.onRightPressed: root.viewMode = 1

            Repeater {
                model: ["Today", "This Week"]

                Rectangle {
                    width: tabLabel.implicitWidth + 20
                    height: 28
                    radius: 6
                    color: root.viewMode === index ? (viewTabs.activeFocus ? Theme.adapt("#333333") : Theme.adapt("#262626")) : "transparent"

                    Text {
                        id: tabLabel

                        anchors.centerIn: parent
                        text: modelData
                        font.pixelSize: 12
                        color: root.viewMode === index ? Theme.adapt("#ffffff")
                             : tabMa.containsMouse ? Theme.adapt("#cccccc") : Theme.adapt("#808080")
                    }

                    MouseArea {
                        id: tabMa

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.viewMode = index
                    }
                }
            }
        }

        Item {
            id: dayPicker

            Layout.fillWidth: true
            height: 46
            visible: root.viewMode === 1

            activeFocusOnTab: true
            Keys.onLeftPressed: root.stepDay(-1)
            Keys.onRightPressed: root.stepDay(1)

            RowLayout {
                anchors.fill: parent
                spacing: 4

                Repeater {
                    model: root.weekDays

                    Rectangle {
                        id: dayCell

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        property bool selected: root.selectedDayKey === modelData.key
                        property bool enabled_: modelData.hasData === true
                        color: selected ? (dayPicker.activeFocus ? Theme.adapt("#333333") : Theme.adapt("#262626"))
                            : (dayMa.containsMouse && dayCell.enabled_ ? Theme.hover : "transparent")
                        opacity: dayCell.enabled_ ? 1 : 0.35

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: 10
                                color: dayCell.selected ? Theme.adapt("#ffffff") : (modelData.isToday ? Theme.adapt("#cccccc") : Theme.textDim)
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.dayNum
                                font.pixelSize: 12
                                font.weight: dayCell.selected || modelData.isToday ? Font.Medium : Font.Normal
                                color: dayCell.selected ? Theme.adapt("#ffffff") : (modelData.isToday ? Theme.text : Theme.adapt("#808080"))
                            }
                        }

                        MouseArea {
                            id: dayMa

                            anchors.fill: parent
                            enabled: dayCell.enabled_
                            hoverEnabled: true
                            cursorShape: dayCell.enabled_ ? Qt.PointingHandCursor : Qt.ArrowCursor
                            onClicked: root.selectedDayKey = dayCell.selected ? "" : modelData.key
                        }

                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: {
                    if (viewMode === 0)
                        return Qt.formatDate(new Date(), "dddd, MMMM d");

                    if (selectedDayKey === "")
                        return "Past 7 days";

                    for (var i = 0; i < weekDays.length; i++) {
                        if (weekDays[i].key === selectedDayKey)
                            return Qt.formatDate(weekDays[i].date, "dddd, MMMM d");
                    }
                    return "";
                }
                color: Theme.textDim
                font.pixelSize: 12
                font.weight: Font.Medium
                Layout.fillWidth: true
            }

            Text {
                // formatData needs the state loaded
                text: state._loaded ? (state.formatData(root.totalMB) + " total") : ""
                color: Theme.textDim
                font.pixelSize: 12
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Text {
                anchors.centerIn: parent
                visible: root.currentList.length === 0
                text: state._loaded ? "No usage recorded yet" : "Loading…"
                font.pixelSize: 13
                color: Theme.textDim
            }

            ScrollView {
                anchors.fill: parent
                visible: root.currentList.length > 0
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                Column {
                    id: appColumn

                    width: parent.width
                    spacing: 14

                    Repeater {
                        model: root.currentList

                        InternetUsageBar {
                            width: appColumn.width
                            appName: modelData.name
                            megabytes: modelData.secs
                            maxMegabytes: root.currentMax
                            isActive: modelData.isActive
                            dataLabel: modelData.timeLabel
                            iconName: modelData.iconName
                        }
                    }
                }
            }
        }

        Item {
            Layout.fillWidth: true
            height: 28
            visible: state.activeApp !== "" && state._loaded

            RowLayout {
                anchors.fill: parent
                spacing: 8

                Item {
                    Layout.preferredWidth: 16
                    Layout.preferredHeight: 16
                    clip: true

                    Image {
                        id: footerIcon

                        anchors.fill: parent
                        sourceSize.width: 16
                        sourceSize.height: 16
                        source: {
                            if (!state._loaded || state.activeApp === "")
                                return "";

                            var name = root._guessIcon(state.activeApp);
                            return Quickshell.iconPath(name, true);
                        }
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                        visible: status === Image.Ready
                    }
                }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    visible: !footerIcon.visible && state.activeApp !== ""
                    color: Theme.adapt("#808080")

                    SequentialAnimation on opacity {
                        running: state.activeApp !== "" && root.visible
                        loops: Animation.Infinite

                        NumberAnimation {
                            to: 0.2
                            duration: 600
                            easing.type: Easing.InOutSine
                        }

                        NumberAnimation {
                            to: 1
                            duration: 600
                            easing.type: Easing.InOutSine
                        }
                    }
                }

                Text {
                    text: "Latest: "
                    color: Theme.textDim
                    font.pixelSize: 12
                }

                Text {
                    text: state.activeApp
                    color: Theme.text
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: (state._loaded && state.activeApp !== "") ? state.formatData(state.currentSessionMB) : ""
                    color: Theme.adapt("#999999")
                    font.pixelSize: 12
                }
            }
        }
    }
}
