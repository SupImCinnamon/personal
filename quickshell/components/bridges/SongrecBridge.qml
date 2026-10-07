pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: bridge

    // idle | listening | found | none
    property string state: "idle"
    property var result: null           // { title, artist, art, url }

    readonly property int timeoutMs: 15000
    readonly property string device:
        "alsa_output.usb-HP__Inc_HyperX_Cloud_III_S_Wireless_C1V53101QZ-00.analog-stereo.monitor"

    property real startedAt: 0
    property real now: 0
    readonly property int elapsed: state === "listening" ? Math.max(0, now - startedAt) : 0
    readonly property bool finished: state === "found" || state === "none"

    readonly property string phrase:
        elapsed < 5000  ? "Listening..." :
        elapsed < 10000 ? "Trying harder..." :
                          "Not quite easy..."

    function start() {
        if (state === "listening" || proc.running) return
        result = null
        startedAt = Date.now()
        now = startedAt
        state = "listening"
        proc.running = true
    }

    function dismiss() {
        if (state === "listening") proc.running = false   // cancel
        state = "idle"
        result = null
    }

    function toggle() { state === "idle" ? start() : dismiss() }

    function handleOutput(text) {
        if (state !== "listening") return      // cancelled or already timed out
        let o = null
        try { o = JSON.parse(text) } catch (e) {
            const ls = text.trim().split("\n").filter(l => l.trim())
            try { o = JSON.parse(ls[ls.length - 1]) } catch (e2) {}
        }
        const t = o?.track
        if (!t?.title) { state = "none"; return }
        result = {
            title: t.title,
            artist: t.subtitle || "",
            art: t.images?.coverarthq || t.images?.coverart || "",
            url: t.share?.href || t.url || ""
        }
        state = "found"
    }

    Process {
        id: proc
        command: ["sh", "-c", "exec songrec recognize --json -d \"" + bridge.device + "\" 2>/dev/null"]
        stdout: StdioCollector {
            onStreamFinished: bridge.handleOutput(text)
        }
    }

    Timer {
        interval: 100
        repeat: true
        running: bridge.state === "listening"
        onTriggered: {
            bridge.now = Date.now()
            if (bridge.elapsed >= bridge.timeoutMs) {
                bridge.state = "none"      // set first so the killed process's empty output is ignored
                proc.running = false
            }
        }
    }
}