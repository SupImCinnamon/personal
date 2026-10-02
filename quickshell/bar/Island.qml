pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
    id: root

    property bool expanded: false
    property bool hovered: false

    property var notification: null
    property var media: null
    property var recording: null

    property string pinned: ""

    readonly property string activity:
        notification ? "notification" :
        media ? "media" :
        "idle"

    readonly property var activities: {
        const out = []
        if (notification) out.push("notification")      // interrupts everything
        if (media)        out.push("media")      // outranks recording
        if (recording)    out.push("recording")
        if (out.length === 0) out.push("idle")
        return pinned && out.includes(pinned)
            ? [pinned, ...out.filter(a => a !== pinned)]
            : out
    }

    readonly property var bubbleCapable: ["recording"]
    readonly property string primary: activities[0]
    readonly property string secondary: activities.slice(1).find(a => bubbleCapable.includes(a)) ?? ""

    readonly property var layouts: ({
        idle:         { compact: Qt.size(110, 30), expanded: Qt.size(420, 120) },
        media:        { compact: Qt.size(150, 30), expanded: Qt.size(420, 185) },
        notification: { compact: Qt.size(200, 30), expanded: Qt.size(420, 150) }
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
    onPrimaryChanged: console.log("primary:", primary, JSON.stringify(activities))
    Timer {
        interval: 3250
        running: root.notification !== null && !root.hovered && !root.expanded
        onTriggered: root.clearNotification()
    }
    FrameAnimation {
        // only emit the signal when the position is actually changing.
        running: media.playbackState == MprisPlaybackState.Playing && root.expanded
        // emit the positionChanged signal every frame.
        onTriggered: media.positionChanged()
    }
}