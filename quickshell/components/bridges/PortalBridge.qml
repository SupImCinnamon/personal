import QtQuick
import Quickshell
import Quickshell.Io
import qs.bar

Item {
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

                if (m.type === "open" || m.type === "save" || m.type === "appchooser") {
                    if (root.portal) root.portalCancel()   // don't leave an old request hanging
                    root.portal = m
                    root.expanded = true
                } else if (m.type === "close" && root.portal && root.portal.id === m.id) {
                    root.portalDone()
                }
            }
        }
    }

    Timer {
        interval: 2000; repeat: true
        running: !portalSock.connected
        onTriggered: portalSock.connected = true
    }
}
