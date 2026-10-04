import QtQuick
import qs.utils

Column {
    id: content
    property var index: null
    anchors.fill: parent
    anchors.margins: 20
    spacing: 15

    readonly property var actions: [
        { id: "convert", icon: Icons.convert, label: "Convert" },
        { id: "ocr",     icon: Icons.ocr,     label: "Extract text" },
        { id: "resize",  icon: Icons.resize,  label: "Resize" },
        { id: "copy",    icon: Icons.copy,    label: "Copy" }
    ]
    readonly property var formats: [
        { id: "jpeg", label: "JPEG" },
        { id: "png",  label: "PNG" },
        { id: "webp", label: "WebP" },
        { id: "avif", label: "AVIF" }
    ]

    property string hoveredAction: ""
    property string hoveredFormat: ""
    property bool chipsOpen: false
    property string lastFormat: "webp"
    readonly property real extraHeight: chipsOpen ? 40 + content.spacing : 0
    
    function hitTest(src, x, y) {
        for (let i = 0; i < tiles.count; i++) {
            const t = tiles.itemAt(i)
            if (t && t.contains(t.mapFromItem(src, x, y)))
                return { kind: "action", id: actions[i].id }
        }
        if (chipsOpen) {
            for (let i = 0; i < chips.count; i++) {
                const c = chips.itemAt(i)
                if (c && c.contains(c.mapFromItem(src, x, y)))
                    return { kind: "format", id: formats[i].id }
            }
        }
        return { kind: "none", id: "" }
    }

    function updateDrag(src, x, y) {
        const h = hitTest(src, x, y)
        hoveredFormat = h.kind === "format" ? h.id : ""
        hoveredAction = h.kind === "action" ? h.id : (h.kind === "format" ? "convert" : "")
    }

    function handleDrop(src, x, y) {
        const h = hitTest(src, x, y)
        let result = { action: "", format: "" }
        if (h.kind === "format") {
            lastFormat = h.id
            result = { action: "convert", format: h.id }
        } else if (h.kind === "action") {
            result = { action: h.id, format: h.id === "convert" ? lastFormat : "" }
        }
        dragLeft()
        return result
    }

    function dragLeft() {
        dwell.stop(); collapseChips.stop()
        hoveredAction = ""; hoveredFormat = ""; chipsOpen = false
    }

    onHoveredActionChanged: {
        if (hoveredAction === "convert") {
            collapseChips.stop()
            if (!chipsOpen) dwell.restart()
        } else {
            dwell.stop()
            if (chipsOpen) collapseChips.restart()
        }
    }
    Timer { id: dwell;         interval: 300; onTriggered: content.chipsOpen = true }
    Timer { id: collapseChips; interval: 150; onTriggered: content.chipsOpen = false }

    Row {
        spacing: 10
        Rectangle {
            width: 40; height: 40; radius: 12
            color: root.backgroundColor
            Text {
                anchors.centerIn: parent
                text: Icons.image
                color: "white"
                font.family: root.iconFont
                font.pixelSize: root.fontSize + 6
            }
        }
        Column {
            Text { text: "screenshot.png"; color: "white"
                   font.family: root.font; font.pixelSize: root.fontSize - 2 }
            Text { text: "PNG image, 2.4 MB"; color: root.textColorSecondary
                   font.family: root.font; font.pixelSize: root.fontSize - 2 }
        }
    }

    Row {
        spacing: 15
        Repeater {
            id: tiles
            model: content.actions
            delegate: Item {
                id: tile
                required property var modelData
                readonly property bool hot: content.hoveredAction === modelData.id
                width: 120; height: 75

                Rectangle {
                    anchors.fill: parent
                    radius: 16
                    color: tile.hot ? root.accentBackground : root.backgroundColor
                    scale: tile.hot ? 1.06 : 1
                    Behavior on scale { NumberAnimation { duration: 200 } }
                    border.width: tile.hot ? 1 : 0
                    border.color: tile.hot ? root.accent : "transparent"

                    Column {
                        spacing: 5
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.icon
                            color: tile.hot ? root.accentSecondary : root.textColor
                            font.family: root.iconFont
                            font.pixelSize: root.fontSize + 4
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: tile.modelData.label
                            color: root.textColorSecondary
                            font.family: root.font
                            font.pixelSize: root.fontSize - 4
                        }
                    }
                }
            }
        }
    }

    Row {
        visible: content.chipsOpen
        spacing: 15
        Repeater {
            id: chips
            model: content.formats
            delegate: Item {
                id: chip
                required property var modelData
                readonly property bool hot: content.hoveredFormat === modelData.id
                width: 120; height: 40

                Rectangle {
                    anchors.fill: parent
                    radius: 14
                    color: chip.hot ? root.accentBackground : root.backgroundColor
                    border.width: 1
                    border.color: chip.hot ? root.accent
                                : chip.modelData.id === content.lastFormat ? root.textColorSecondary
                                : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: chip.modelData.label
                        color: chip.hot ? root.accentSecondary : root.textColor
                        font.family: root.font
                        font.pixelSize: root.fontSize - 2
                    }
                }
            }
        }
    }
}