import QtQuick

// Drags a row of a Column to a new place. The other rows make way as it
// passes them, and it settles into its place once dropped. The rows can be
// of any height. While a drag lasts, the Column's Repeater shows the rows in
// `order` (see arrange()), and the dragged row's content sits at `top`.
QtObject {
    id: root

    required property Column column
    required property Repeater repeater
    // The values' property that tells them apart
    property string keyProp: "id"

    // While a drag lasts: the rows' keys in their new order, the dragged
    // row's key, and the top of its content in the column
    property var order: null
    property var key: null
    property real top: 0
    readonly property bool active: root.key !== null

    property real _grab: 0
    property int _first: 0
    property int _last: 0

    // The new order, on dropping the row
    signal dropped(var ids)

    property NumberAnimation _settle: NumberAnimation {
        target: root
        property: "top"
        duration: 150
        easing.type: Easing.OutCubic
        onFinished: root._finish()
    }

    // `values` (objects with a keyProp) in the drag's order
    function arrange(values: var): var {
        const order = root.order;
        if (!order)
            return values;

        const prop = root.keyProp;
        const list = order.map(key => values.find(v => v[prop] === key)).filter(v => v !== undefined);
        return list.concat(values.filter(v => !order.includes(v[prop])));
    }

    // ids: the rows' keys as shown; y: the press, in the column. The row can
    // move to the places first to last
    function start(ids: var, key: var, y: real, first: int, last: int): void {
        root._settle.stop();
        root._finish();
        const at = root._slotY(ids.indexOf(key));
        root._grab = y - at;
        root.top = at;
        root._first = first;
        root._last = last;
        root.order = ids;
        root.key = key;
    }

    function move(y: real): void {
        if (!root.active || root._settle.running)
            return;

        root.top = y - root._grab;
        // The row's place: after every other row whose middle is above its own
        const self = root.order.indexOf(root.key);
        const middle = root.top + root._height(self) / 2;
        let target = 0;
        let at = 0;
        for (let i = 0; i < root.order.length; i++) {
            const height = root._height(i);
            if (i !== self && at + height / 2 < middle)
                target++;
            at += height + root.column.spacing;
        }
        target = Math.max(root._first, Math.min(root._last, target));
        if (target === self)
            return;

        const order = root.order.slice();
        order.splice(self, 1);
        order.splice(target, 0, root.key);
        root.order = order;
    }

    function end(): void {
        if (!root.active || root._settle.running)
            return;

        root.dropped(root.order);
        root._settle.from = root.top;
        root._settle.to = root._slotY(root.order.indexOf(root.key));
        root._settle.restart();
    }

    function _finish(): void {
        root.key = null;
        root.order = null;
    }

    function _height(i: int): real {
        return root.repeater.itemAt(i)?.height ?? 0;
    }

    // Where row i sits once the Column is done moving it
    function _slotY(i: int): real {
        let y = 0;
        for (let j = 0; j < i; j++)
            y += root._height(j) + root.column.spacing;
        return y;
    }
}
