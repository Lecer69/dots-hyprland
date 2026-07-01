import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.tools

Rectangle {
    id: root

    // 0 = today, 1 = this week (specific day selected within the week)
    property int viewMode: 0
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

    // Cache of per-app static enrichment
    // Avoids re-hashing color and re-resolving icons every single tick.
    property var _enrichCache: ({})

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
            _weekDirty = true; // week totals include today, so mark stale
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
            selectedDayKey = ""; // default to whole-week summary when switching in
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

        return AppSearch.guessIcon(appClass);
    }

    radius: 14
    color: "#0f0f0f"
    clip: true
    border.color: "#2a2a2a"
    border.width: 1

    InternetUsageState {
        id: state
    }

    Connections {
        function onTriggered() {
            if (root.visible)
                root._refresh();
            else
                root._todayDirty = root._weekDirty = root._daysDirty = true; // mark stale, rebuild on next show
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

    // header
    Rectangle {
        id: header

        width: parent.width
        height: 52
        color: "transparent"

        Text {
            anchors.left: parent.left
            anchors.leftMargin: 24
            anchors.verticalCenter: parent.verticalCenter
            text: "Internet Usage"
            font.pixelSize: 15
            font.weight: Font.DemiBold
            color: "#dddddd"
        }

        Rectangle {
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: closeHover.containsMouse ? "#252525" : "transparent"

            Text {
                anchors.centerIn: parent
                text: "✕"
                font.pixelSize: 12
                color: "#888888"
            }

            MouseArea {
                id: closeHover

                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.closeRequested()
            }

        }

    }

    Rectangle {
        id: divider

        anchors.top: header.bottom
        width: parent.width
        height: 1
        color: "#222222"
    }

    // body
    ColumnLayout {
        anchors.top: divider.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 24
        anchors.topMargin: 20
        spacing: 14

        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 8
            color: "#1a1a1a"
            border.color: "#2a2a2a"
            border.width: 1

            // tab toggle
            RowLayout {
                anchors.fill: parent
                anchors.margins: 3
                spacing: 3

                Repeater {
                    model: ["Today", "This Week"]

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: root.viewMode === index ? "#252525" : (tabMa.containsMouse ? "#1e1e1e" : "transparent")

                        Text {
                            anchors.centerIn: parent
                            text: modelData
                            font.pixelSize: 12
                            font.weight: root.viewMode === index ? Font.DemiBold : Font.Normal
                            color: root.viewMode === index ? "#dddddd" : "#555555"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 100
                                }
                            }
                        }

                        MouseArea {
                            id: tabMa

                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.viewMode = index
                        }

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }
        }

        // weekday picker (week mode only)
        Rectangle {
            Layout.fillWidth: true
            height: 46
            radius: 8
            color: "#141414"
            border.color: "#222222"
            border.width: 1
            visible: root.viewMode === 1

            RowLayout {
                anchors.fill: parent
                anchors.margins: 4
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
                        color: selected ? "#252525" : (dayMa.containsMouse && dayCell.enabled_ ? "#1c1c1c" : "transparent")
                        border.color: modelData.isToday ? "#3a3a3a" : "transparent"
                        border.width: 1
                        opacity: dayCell.enabled_ ? 1 : 0.35

                        Column {
                            anchors.centerIn: parent
                            spacing: 1

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.pixelSize: 10
                                font.weight: dayCell.selected ? Font.DemiBold : Font.Normal
                                color: dayCell.selected ? "#dddddd" : (modelData.isToday ? "#888888" : "#555555")
                            }

                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.dayNum
                                font.pixelSize: 12
                                font.weight: dayCell.selected ? Font.DemiBold : Font.Normal
                                color: dayCell.selected ? "#eeeeee" : (modelData.isToday ? "#999999" : "#666666")
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

                        Behavior on color {
                            ColorAnimation {
                                duration: 100
                            }
                        }
                    }
                }
            }
        }

        // summary
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
                color: "#444444"
                font.pixelSize: 11
                Layout.fillWidth: true
            }

            Text {
                // Guard: only call formatData once state is loaded
                text: state._loaded ? (state.formatData(root.totalMB) + " total") : ""
                color: "#3a3a3a"
                font.pixelSize: 11
                font.family: "monospace"
            }
        }

        // Apps
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Column {
                anchors.centerIn: parent
                spacing: 10
                visible: root.currentList.length === 0

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "⇅"
                    font.pixelSize: 30
                    color: "#2a2a2a"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: state._loaded ? "No usage recorded yet" : "Loading…"
                    font.pixelSize: 12
                    color: "#3a3a3a"
                }
            }

            ScrollView {
                anchors.fill: parent
                visible: root.currentList.length > 0
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                Column {
                    id: appColumn

                    width: parent.width
                    spacing: 13

                    Repeater {
                        model: root.currentList

                        InternetUsageBar {
                            width: appColumn.width
                            appName: modelData.name
                            megabytes: modelData.secs
                            maxMegabytes: root.currentMax
                            accent: modelData.color
                            isActive: modelData.isActive
                            dataLabel: modelData.timeLabel
                            iconName: modelData.iconName
                        }
                    }
                }
            }
        }

        // active transfer footer
        Rectangle {
            Layout.fillWidth: true
            height: 34
            radius: 8
            color: "#111111"
            border.color: "#1c1c1c"
            border.width: 1
            visible: state.activeApp !== "" && state._loaded

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
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
                    color: state._loaded && state.activeApp !== "" ? state.appColor(state.activeApp) : "#444"

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
                    color: "#3a3a3a"
                    font.pixelSize: 11
                }

                Text {
                    text: state.activeApp
                    color: "#666666"
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }

                Text {
                    text: (state._loaded && state.activeApp !== "") ? state.formatData(state.currentSessionMB) : ""
                    color: (state._loaded && state.activeApp !== "") ? state.appColor(state.activeApp) : "#444444"
                    font.pixelSize: 11
                    font.family: "monospace"
                    font.bold: true
                }
            }
        }
    }
}
