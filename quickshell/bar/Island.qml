pragma Singleton
import QtQuick
import Quickshell

Singleton {
    id: root

    property bool expanded: false
    property bool hovered: false

    // One property per activity source, null when inactive
    property var notification: null
    // property var media: null

    // Priority order lives here; first non-null wins
    readonly property string activity:
        notification ? "notification" :
        // media ? "media" :
        "idle"

    // Compact/expanded sizes per activity
    readonly property var layouts: ({
        idle:         { compact: Qt.size(110, 30), expanded: Qt.size(420, 120) },
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
        expanded = false   // falls back to idle automatically
    }

    // Auto-dismiss, paused while the user is interacting
    Timer {
        interval: 5000
        running: root.notification !== null && !root.hovered && !root.expanded
        onTriggered: root.clearNotification()
    }
}