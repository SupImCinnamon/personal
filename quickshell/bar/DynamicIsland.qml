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
    property bool lyricsOpen: false
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

            WlrLayershell.layer: (Island.notification || Island.islandPinned) ? WlrLayer.Overlay : WlrLayer.Top

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

            DropArea {
                anchors.fill: parent

                onEntered: (drag) => {
                    drag.accept(Qt.CopyAction);
                    Island.dragDrop = "drag";

                    if (String(drag.text).includes("www.youtube.com")) {
                        Island.dragDropType = "youtubeVideo";
                    }
                }

                onExited: {
                    Island.dragDrop = null
                    Island.dragDropType = null
                }

                onDropped: (drop) => {
                    drop.accept(Qt.CopyAction);
                    if (String(drop.text).includes("www.youtube.com") && !ytDlProc.running) {
                        ytDlProc.command = ["sh", "-c", Island.youtubeToYtdl(String(drop.text))]
                        ytDlProc.running = true;
                    }
                }
            }
            ClippingRectangle {
                id: pill
                x: (parent.width - width) / 2

                readonly property var layout: Island.layouts[Island.primary]
                readonly property size target: Island.currentSize

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
                    case "controlCenter:expanded":   return controlCenterExpanded

                    default:
                        console.warn("viewFor: no view for", activity, kind)
                        return null
                    }
                }

                width: target.width + (Island.hovered && !Island.expanded ? 16 : 0)
                height: target.height + (Island.hovered && !Island.expanded ? 2 : 0)
                radius: Math.min(height / 2, 34)
                color: root.pillColor
                clip: false

                Behavior on width  { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                    onContainsMouseChanged: Island.hovered = containsMouse
                    onClicked: mouse =>{
                        if (mouse.button == Qt.RightButton) {
                            Island.controlCenter = true;
                            Island.expanded = true;
                        } else if (mouse.button == Qt.MiddleButton) {
                            Island.islandPinned = !Island.islandPinned
                        } else {
                            Island.expanded = !Island.expanded
                            console.log(Island.primary)
                            if (Island.controlCenter) {
                                Island.controlCenter = null;
                            }
                        }
                    }
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: pill.viewFor(Island.primary, Island.expanded ? "expanded" : "compact") ?? pill.viewFor("idle", Island.expanded ? "expanded" : "compact")
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
                    id: controlCenterExpanded
                    ControlCenterExpanded {}
                }
            }

            Rectangle {
                id: bubble
                readonly property bool shown:
                    (Island.secondary !== ""
                    && !Island.expanded
                    && pill.viewFor(Island.secondary, "bubble") !== null)

                anchors.left: pill.right
                anchors.leftMargin: shown ? 8 : 0
                y: 0
                width: shown ? 30 : 0
                height: 30
                radius: height / 2
                color: root.pillColor
                opacity: shown ? 1 : 0
                clip: true

                Behavior on anchors.leftMargin { NumberAnimation { duration: 150 } }
                Behavior on width   { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }
}