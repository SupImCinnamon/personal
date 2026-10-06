pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Singleton {
    id: bridge
    property var state: null
    readonly property var incoming: state?.incoming ?? null
    readonly property var call: state?.call ?? null
    readonly property var screensharing: state?.call?.streaming ?? null

    function send(cmd) {
        sock.write(JSON.stringify({ cmd: cmd }) + "\n")
        sock.flush()
    }

    Socket {
        id: sock
        path: Quickshell.env("XDG_RUNTIME_DIR") + "/island-discord.sock"
        connected: true
        parser: SplitParser {
            onRead: data => { try { bridge.state = JSON.parse(data) } catch (e) {} }
        }
    }

    Timer {
        interval: 2000
        repeat: true
        running: !sock.connected
        onTriggered: { sock.connected = false; sock.connected = true }
    }

    onIncomingChanged: {
        Island.incomingCall = incoming?.channelId ? incoming : null
        Island.expanded = incoming?.channelId ? true : false
    }

    onCallChanged: {
        Island.call = call?.channelId ? call : null
        //Island.expanded = true
    }

    property real now: Date.now()

    readonly property string durationText: {
        if (!call?.startedAt) return "00:00"

        let elapsedMs = now - call.startedAt

        let totalSeconds = Math.floor(elapsedMs / 1000)
        let seconds = totalSeconds % 60
        let minutes = Math.floor(totalSeconds / 60) % 60
        let hours = Math.floor(totalSeconds / 3600)

        let pad = (num) => String(num).padStart(2, '0')
        if (hours > 0) {
            return pad(hours) + ":" + pad(minutes) + ":" + pad(seconds)
        } else {
            return pad(minutes) + ":" + pad(seconds)
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: bridge.call !== null
        triggeredOnStart: true
        onTriggered: bridge.now = Date.now()
    }
    
}