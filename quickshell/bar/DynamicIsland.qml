import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Wayland
import qs.utils
import qs.components.compact
import qs.components.expanded

pragma ComponentBehavior: Bound

Scope {
    id: barRoot
    property int barCount: 6
    property int mediaAnimDuration: 150
    property bool controlCenterOpen: false
    property var barLevels: {
        let initialLevels = [];
        for(let i = 0; i < barRoot.barCount; i++) {
            initialLevels.push(0.0);
        }
        return initialLevels;
    }

    property string cavaConfig: [
        "[general]",
        "bars = " + barRoot.barCount,
        "framerate = 60",
        "[output]",
        "method = raw",
        "raw_target = /dev/stdout",
        "data_format = ascii",
        "ascii_max_range = 1000",
        "bar_delimiter = 59",
    ].join("\\n");

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process {
        id: cavaProc
        command: ["bash", "-c", "cava -p <(printf '" + barRoot.cavaConfig + "\\n')"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                let clean = data.trim();
                if (clean.length == 0) return;

                let tokens = clean.split(";");
                let availableTokens = Math.min(tokens.length, barRoot.barCount);
                let nextLevels = [];

                for(let i = 0; i < barRoot.barCount; i++) {
                    let rawAmplitude = i < availableTokens ? (parseInt(tokens[i]) || 0) : 0;
                    let normalizedLevel = Math.max(0.0, Math.min(1.0, rawAmplitude / 1000));
                    nextLevels.push(normalizedLevel);
                }
                barRoot.barLevels = nextLevels;
            }
        }
    }
    
    Process {
        id: ytDlProc
        running: false

        onExited: (exitCode, exitStatus) => {
            Island.dragDrop = null;
            Island.dragDropType = null;
            Island.dragDropContent = null;
        }
    }

    Process {
        id: mimeProc
        property string target
        command: ["file", "--brief", "--mime-type", target]
        stdout: StdioCollector {
            onStreamFinished: {
                const mime = text.trim()
                if (mime == "inode/directory") {
                    Island.dragDropType = "folder"
                } else if (mime.startsWith("image/")) {
                    Island.dragDropType = "image"
                } else if (mime.startsWith("video/")) {
                    Island.dragDropType = "video"
                } else if (mime.startsWith("text/plain")) {
                    Island.dragDropType = "text"
                }
            }
        }
    }

    Process {
        id: infoProc
        property string path
        command: ["sh", "-c",
            'if [ -d "$1" ]; then echo inode/directory; ls -A -- "$1" | wc -l; '
        + 'else file -L -b --mime-type -- "$1"; stat -L -c %s -- "$1"; fi',
            "sh", path]
        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n")
                const mime = lines[0] ?? ""
                const n = parseInt(lines[1]) || 0
                console.log(mime)

                if (mime === "inode/directory") {
                    Island.dragDropType = "folder"
                    Island.dragDropMeta = "Folder, " + n + (n === 1 ? " item" : " items")
                } else {
                    if (mime.startsWith("image/"))      Island.dragDropType = "image"
                    else if (mime.startsWith("video/")) Island.dragDropType = "video"
                    Island.dragDropMeta = barRoot.describe(mime) + ", " + barRoot.formatSize(n)
                }
            }
        }
    }

    function formatSize(bytes) {
        const units = ["B", "KB", "MB", "GB", "TB"]
        let i = 0
        while (bytes >= 1000 && i < units.length - 1) { bytes /= 1000; i++ }
        return (i === 0 ? bytes : bytes.toFixed(1)) + " " + units[i]
    }

    function describe(mime) {
        const overrides = { "x-matroska": "MKV", "quicktime": "MOV", "x-msvideo": "AVI" }
        const [kind, sub = ""] = mime.split("/")
        const raw = sub.split("+")[0].replace(/^(x-|vnd\.)/, "")
        const name = overrides[sub] ?? raw.toUpperCase()

        if (kind === "image" || kind === "video" || kind === "audio") return name + " " + kind
        if (mime === "application/pdf") return "PDF document"
        if (kind === "text") return "Text file"
        return name + " file"
    }

    Process {
        id: nightLightProc
        command: ["wlsunset", "-t", "5000"]
        running: false
    }

    Timer {
        interval: 1000
        repeat: true
        running: Island.media && Island.media.playbackState === MprisPlaybackState.Playing
        onTriggered: Island.media.positionChanged()
    }

    ColorQuantizer {
        id: quant
        source: Island.media ? Island.media.trackArtUrl : ""
        depth: 8
        rescaleSize: 64
    }

    readonly property color accent: {
        const cols = quant.colors;
        if (!cols || cols.length === 0) return "white";

        let best = cols[0], bestScore = -1;
        for (const c of cols) {
            const score = c.hsvSaturation * c.hsvValue;
            if (score > bestScore) { best = c; bestScore = score; }
        }
        return Qt.hsva(best.hsvHue, best.hsvSaturation, Math.max(0.75, best.hsvValue), 1);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            screen: modelData

            WlrLayershell.layer: (Island.notification || Island.islandPinned || Island.portal) ? WlrLayer.Overlay : WlrLayer.Top
            WlrLayershell.keyboardFocus: (Island.portal && Island.expanded) ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
            anchors.top: true
            margins.top: 5
            exclusiveZone: Config.reservedSpace
            color: "transparent"

            implicitWidth: Config.maxWidth
            implicitHeight: Config.maxHeight

            mask: Region {
                item: pill
                regions: [ Region { item: bubble } ]
            }

            Rectangle {
                id: pill
                width: target.width + extraWidth + (Island.hovered && !Island.expanded ? 16 : 0)
                height: target.height + extraHeight + (Island.hovered && !Island.expanded ? 2 : 0)
                x: (parent.width - width) / 2
                radius: Math.min(height / 2, 34)
                color: root.pillColor
                clip: false

                readonly property var layout: Island.layouts[Island.primary]
                readonly property size target: Island.currentSize

                readonly property real extraWidth: contentLoader.item?.extraWidth ?? 0
                readonly property real extraHeight: contentLoader.item?.extraHeight ?? 0

                function viewFor(activity, kind) {
                    switch (activity + ":" + kind) {
                    case "idle:compact":             return idleCompact
                    case "idle:expanded":            return idleExpanded
                    case "notification:compact":     return notifCompact
                    case "notification:expanded":    return notifExpanded
                    case "media:compact":            return mediaCompact
                    case "media:expanded":           return mediaExpanded
                    case "dragDrop:compact":         return dragDropCompact
                    case "dragDrop:expanded":        return dragDropExpanded
                    case "controlCenter:compact":    return controlCenterCompact
                    case "controlCenter:expanded":   return controlCenterExpanded
                    case "portal:compact":           return portalCompact
                    case "portal:expanded":          return portalExpanded
                    case "appLauncher:compact":      return appLauncherCompact
                    case "appLauncher:expanded":     return appLauncherExpanded
                    case "call:compact":             return callCompact
                    case "call:expanded":            return callExpanded
                    case "incomingCall:compact":     return incomingCallCompact
                    case "incomingCall:expanded":    return incomingCallExpanded

                    default:
                        console.warn("viewFor: no view for", activity, kind)
                        return null
                    }
                }


                Behavior on width  { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }

                DropArea {
                    id: pillDrop
                    anchors.fill: parent

                    onEntered: (drag) => {
                        drag.accept(Qt.CopyAction)
                        Island.dragDrop = true
                        Island.dragDropContent = drag.text

                        if (String(drag.text).includes("www.youtube.com")) {
                            Island.dragDropType = "youtubeVideo"
                            return
                        }
                        if (drag.hasUrls) {
                            const path = decodeURIComponent(drag.urls[0].toString().replace("file://", ""))
                            Island.dragDropName = path.split("/").pop()
                            Island.dragDropCount = drag.urls.length
                            Island.dragDropMeta = ""
                            infoProc.path = path
                            infoProc.running = true
                        }
                        Island.expanded = true
                    }

                    onPositionChanged: (drag) => {
                        const v = contentLoader.item
                        if (v && v.updateDrag) v.updateDrag(pillDrop, drag.x, drag.y)
                    }

                    onExited: {
                        const v = contentLoader.item
                        if (v && v.dragLeft) v.dragLeft()
                        mimeProc.running = false
                        Island.dragDrop = null
                        Island.dragDropType = null
                        Island.expanded = false
                        Island.dragDropName = ""
                        Island.dragDropMeta = ""
                        Island.dragDropCount = 0
                    }

                    onDropped: (drop) => {
                        drop.accept(Qt.CopyAction)

                        if (String(drop.text).includes("www.youtube.com") && !ytDlProc.running) {
                            ytDlProc.command = ["sh", "-c", Island.youtubeToYtdl(String(drop.text))]
                            ytDlProc.running = true
                            return;
                        }

                        const v = contentLoader.item
                        if (v && v.handleDrop) {
                            const r = v.handleDrop(pillDrop, drop.x, drop.y)
                            if (r.action) v.runAction(r.action, drop.urls, r.format)
                        }
                        Island.dragDrop = null
                        Island.dragDropType = null
                        Island.expanded = false
                        Island.dragDropName = ""
                        Island.dragDropMeta = ""
                        Island.dragDropCount = 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onContainsMouseChanged: Island.hovered = containsMouse
                    onClicked: mouse => {
                        if (mouse.button == Qt.RightButton) {
                            Island.controlCenter = true;
                            Island.expanded = true;
                        } else if (mouse.button == Qt.MiddleButton) {
                            Island.islandPinned = !Island.islandPinned
                        } else {
                            Island.expanded = !Island.expanded
                            if (Island.controlCenter) {
                                Island.controlCenter = null;
                            }
                        }
                    }
                }

                ClippingRectangle {
                    anchors.fill: parent
                    radius: pill.radius
                    color: "transparent"

                    Loader {
                        id: contentLoader
                        anchors.fill: parent
                        sourceComponent: pill.viewFor(Island.primary, Island.expanded ? "expanded" : "compact") ?? pill.viewFor("idle", Island.expanded ? "expanded" : "compact")
                    }
                }

                Component {
                    id: idleCompact
                    IdleCompact {}
                }

                Component {
                    id: idleExpanded
                    IdleExpanded {}
                }

                Component {
                    id: notifCompact
                    NotificationCompact {}
                }

                Component {
                    id: notifExpanded
                    NotificationExpanded {}
                }

                Component {
                    id: mediaCompact
                    MediaCompact {}
                }

                Component {
                    id: mediaExpanded
                    MediaExpanded {}
                }

                Component {
                    id: dragDropCompact
                    DragDropCompact {}
                }

                Component {
                    id: dragDropExpanded
                    DragDropExpanded {}
                }

                Component {
                    id: controlCenterCompact
                    ControlCenterCompact {}
                }

                Component {
                    id: controlCenterExpanded
                    ControlCenterExpanded {}
                }

                Component {
                    id: portalCompact
                    PortalCompact {}
                }

                Component {
                    id: portalExpanded
                    PortalExpanded {}
                }

                Component {
                    id: appLauncherCompact
                    AppLauncherExpanded {}
                }

                Component {
                    id: appLauncherExpanded
                    AppLauncherExpanded {}
                }

                Component {
                    id: callCompact
                    CallCompact {}
                }

                Component {
                    id: callExpanded
                    CallExpanded {}
                }

                Component {
                    id: incomingCallCompact
                    IncomingCallCompact {}
                }

                Component {
                    id: incomingCallExpanded
                    IncomingCallExpanded {}
                }
            }

            Rectangle {
                id: bubble
                readonly property bool shown:
                    (Island.secondary !== ""
                    && !Island.expanded
                    && pill.viewFor(Island.secondary, "bubble") !== null)

                z: -1
                height: pill.height
                width: height
                y: 0
                radius: height / 2
                color: root.pillColor

                anchors.left: pill.right
                anchors.leftMargin: shown ? 8 : -width
                visible: shown

                Behavior on anchors.leftMargin {
                    SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 }
                }
            }
        }
    }
}