pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool expanded: false
    property bool hovered: false

    property var notification: null
    property var media: null

    readonly property string activity:
        notification ? "notification" :
        media ? "media" :
        "idle"

    readonly property var layouts: ({
        idle:         { compact: Qt.size(110, 30), expanded: Qt.size(420, 120) },
        media:        { compact: Qt.size(150, 30), expanded: Qt.size(420, 120) },
        notification: { compact: Qt.size(180, 30), expanded: Qt.size(420, 150) }
    })

    readonly property size currentSize: {
        const spec = layouts[activity]
        return expanded ? spec.expanded : spec.compact
    }

    function showNotification(n) {
        notification = {
            appName: n.appName,
            image: n.image,
            desktopEntry: n.desktopEntry,
            icon: n.appIcon,
            summary: n.summary,
            body: n.body
        }
        expanded = false
    }

    function clearNotification() {
        notification = null
        expanded = false
    }
    Timer {
        interval: 5000
        running: root.notification !== null && !root.hovered && !root.expanded
        onTriggered: root.clearNotification()
    }
}