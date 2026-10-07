pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Io
import qs.components.bridges

Singleton {
    id: root

    property bool expanded: false
    property bool hovered: false
    property bool islandPinned: false

    property var notification: null
    property var media: null
    property var recording: null
    property var songrec: null

    property var dragDrop: null
    property var dragDropType: null
    property var dragDropContent: null
    property string dragDropName: ""
    property string dragDropMeta: ""
    property int dragDropCount: 0

    property var controlCenter: null
    property var appLauncher: null
    property var portal: null

    property var incoming: DiscordBridge.incoming
    property var incomingCall: null
    property var call: null

    property string pinned: ""

    readonly property string activity:
        portal ? "portal" :
        incomingCall ? "incomingCall" :
        SongrecBridge.state !== "idle" ? "songrec" :
        appLauncher ? "appLauncher" :
        controlCenter ? "controlCenter" :
        dragDrop ? "dragDrop" :
        notification ? "notification" :
        call ? "call" :
        media ? "media" :
        "idle"

    readonly property var activities: {
        const out = []
        if (portal)       out.push("portal")
        if (incomingCall) out.push("incomingCall")
        if (SongrecBridge.state !== "idle") out.push("songrec")
        if (appLauncher)  out.push("appLauncher")
        if (controlCenter)out.push("controlCenter")
        if (dragDrop)     out.push("dragDrop")
        if (notification) out.push("notification")
        if (call)         out.push("call")
        if (media)        out.push("media")
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
        portal:       { compact: Qt.size(150, 30), expanded: Qt.size(560, 210) },
        songrec:      { compact: Qt.size(275, 60), expanded: Qt.size(350, 120) },
        appLauncher:  { compact: Qt.size(150, 30), expanded: Qt.size(640, 440) },
        controlCenter:{ compact: Qt.size(150, 30), expanded: Qt.size(965, 760) },
        notification: { compact: Qt.size(200, 30), expanded: Qt.size(420, 150) },
        call:         { compact: Qt.size(200, 30), expanded: Qt.size(346, 150) },
        incomingCall: { compact: Qt.size(200, 30), expanded: Qt.size(350, 65 ) },
        dragDrop:     { compact: Qt.size(230, 30), expanded: Qt.size(565, 170) },
        media:        { compact: Qt.size(150, 30), expanded: Qt.size(420, 185) },
        idle:         { compact: Qt.size(110, 30), expanded: Qt.size(420, 120) }
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


    function youtubeToYtdl(url) {
        const parsed = new URL(url);

        let videoId;

        if (parsed.hostname === "youtu.be") {
            videoId = parsed.pathname.slice(1);
        } else if (
            parsed.hostname === "youtube.com" ||
            parsed.hostname === "www.youtube.com" ||
            parsed.hostname.endsWith(".youtube.com")
        ) {
            videoId = parsed.searchParams.get("v");

            // Handle /shorts/ID and /embed/ID
            if (!videoId) {
                const match = parsed.pathname.match(/^\/(?:shorts|embed)\/([^/?]+)/);
                videoId = match?.[1];
            }
        }

        if (!videoId) {
            return("invUrl");
        }

        return `yt-dlp -f "bv*+ba/b" --merge-output-format mp4 -P "~/Videos/YTDLP" "https://www.youtube.com/watch?v=${videoId}"`;
    }

    //onPrimaryChanged: console.log("primary:", primary, JSON.stringify(activities))
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

    function portalSend(obj) {
        portalSock.write(JSON.stringify(obj) + "\n")
        portalSock.flush()
    }

    function portalDone() {
        portal = null
        expanded = false
    }

    function portalAccept(uris) {
        if (!portal) return
        portalSend({ type: "result", id: portal.id, uris: uris })
        portalDone()
    }

    function portalCancel() {
        if (!portal) return
        portalSend({ type: "cancel", id: portal.id })
        portalDone()
    }

    Socket {
        id: portalSock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/island-portal.sock"
        connected: true
        parser: SplitParser {
            onRead: data => {
                let m
                try { m = JSON.parse(data) } catch (e) { return }

                if (m.type === "open" || m.type === "save" || m.type === "appchooser" || m.type === "screencast") {
                    if (root.portal) root.portalCancel()   // don't leave an old request hanging
                    root.portal = m
                    root.expanded = true
                } else if (m.type === "close" && root.portal && root.portal.id === m.id) {
                    root.portalDone()
                }
            }
        }
        onConnectedChanged: if (!connected && root.portal) root.portalDone()
    }

    Timer {
        interval: 2000; repeat: true
        running: !portalSock.connected
        onTriggered: portalSock.connected = true
    }

    Connections {
        target: SongrecBridge
        function onStateChanged() {
            if (SongrecBridge.finished) root.expanded = true
            else if (SongrecBridge.state === "idle") root.expanded = false
        }
    }

    Timer {
        interval: 5000
        running: SongrecBridge.finished && !root.hovered
        onTriggered: SongrecBridge.dismiss()
    }
}