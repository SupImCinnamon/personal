import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.utils

Scope {
    id: barRoot
    property int barCount: 6
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

    SystemClock {
        id: clock
        precision: SystemClock.Seconds
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

    ColorQuantizer {
        id: quant
        source: Island.media ? Island.media.trackArtUrl : ""
        depth: 8            // 2^3 = 8 palette colors
        rescaleSize: 64     // downscale first, much faster
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

            anchors.top: true
            margins.top: 5
            exclusiveZone: Config.reservedSpace
            color: "transparent"

            implicitWidth: Config.maxWidth
            implicitHeight: Config.maxHeight

            mask: Region { item: pill }

            Rectangle {
                id: pill

                readonly property var layout: Island.layouts[Island.activity]
                readonly property size target: Island.currentSize

                readonly property var views: ({
                    idle:         { compact: idleCompact,  expanded: idleExpanded  },
                    media:        { compact: mediaCompact, expanded: mediaExpanded },
                    notification: { compact: notifCompact, expanded: notifExpanded }
                })

                anchors.horizontalCenter: parent.horizontalCenter
                y: 0

                width: target.width + (Island.hovered && !Island.expanded ? 16 : 0)
                height: target.height
                radius: Math.min(height / 2, 34)
                color: root.pillColor
                clip: false

                Behavior on width  { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }
                Behavior on height { SpringAnimation { spring: 4; damping: 0.38; epsilon: 0.5 } }

                Loader {
                    anchors.fill: parent
                    sourceComponent: {
                        const v = pill.views[Island.activity]
                        return Island.expanded ? v.expanded : v.compact
                    }
                }

                Component {
                    id: idleCompact
                    Text {
                        anchors.centerIn: parent
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        text: Qt.formatTime(clock.date, "hh:mm")
                        color: root.textColor
                        font { family: root.font; pixelSize: root.fontSize; bold: true }
                    }
                }

                Component {
                    id: idleExpanded
                    Item {
                        anchors.fill: parent
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatTime(clock.date, "hh:mm:ss")
                                color: root.textColor
                                font { family: root.font; pixelSize: root.fontSizeBig; bold: true }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDate(clock.date, "dddd, d MMMM yyyy")
                                color: root.textColorSecondary
                                font { family: root.font; pixelSize: root.fontSize - 2 }
                            }
                        }
                    }
                }

                Component {
                    id: notifCompact
                    Item {
                        anchors.fill: parent
                        RowLayout {
                            anchors.fill: parent
                            spacing: 10
                            Text {
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Island.notification ? Icons.bell : ""
                                color: "white"; font.bold: true
                                font.family: root.iconFont
                                anchors.leftMargin: 10
                                anchors.left: parent.left
                            }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Island.notification ? capitalizeFirstLetter(Island.notification.appName) : ""
                                color: "white";
                                font.bold: true
                                font.family: root.font
                                anchors.leftMargin: 10
                                anchors.left: parent.left
                            }
                        }
                    }
                }

                Component {
                    id: notifExpanded
                    Item {
                        anchors.fill: parent
                        Column {
                            width: parent.width - 32
                            spacing: 15
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.topMargin: 15
                            anchors.leftMargin: 15
                            RowLayout {
                                width: parent.width
                                spacing: 15
                                Image {
                                    Layout.preferredWidth: 40 
                                    Layout.preferredHeight: 40
                                    fillMode: Image.PreserveAspectFit
                                    source: Island.notification ? Quickshell.iconPath(Island.notification.appName) : ""
                                    asynchronous: false
                                    cache: false
                                }
                                Text {
                                    Layout.fillWidth: true 
                                    elide: Text.ElideRight
                                    text: Island.notification ? (Island.notification.summary) : ""
                                    color: "white"; font.bold: true
                                    font.family: root.font
                                }
                            }   
                            Text {
                                width: parent.width
                                elide: Text.ElideRight
                                maximumLineCount: 3
                                wrapMode: Text.Wrap
                                text: Island.notification ? (Island.notification.body || "") : ""
                                color: root.textColorSecondary
                                font.family: root.font
                            }

                        }
                    }
                }

                Component {
                    id: mediaCompact
                    Item {
                        anchors.fill: parent
                        ClippingRectangle {
                            width: 20
                            height: 20
                            radius: 4
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter

                            Image {
                                id: art
                                width: 20
                                height: 20
                                fillMode: Image.PreserveAspectCrop
                                source: Island.media ? Island.media.trackArtUrl : ""
                                asynchronous: false
                                cache: false
                            }
                        }
                        Row {
                            id: bars
                            anchors.right: parent.right
                            anchors.rightMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            height: 22
                            spacing: 3

                            Repeater {
                                model: barRoot.barCount
                                Item {
                                    id: bar
                                    required property int index
                                    readonly property real level: barRoot.barLevels[index] || 0

                                    width: 2
                                    height: bars.height

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width
                                        height: Math.max(width, bar.height * bar.level)
                                        radius: width / 2
                                        color: barRoot.accent

                                        Behavior on color { ColorAnimation { duration: 300 } }

                                        Behavior on height {
                                            NumberAnimation { duration: 50; easing.type: Easing.OutQuad }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Component {
                    id: mediaExpanded
                    Item {
                        anchors.fill: parent
                        Column {
                            anchors.centerIn: parent
                            spacing: 2
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Island.media ? Island.media.trackTitle : ""
                                color: root.textColor
                                font { family: root.font; pixelSize: root.fontSizeBig; bold: true }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Island.media ? Island.media.trackArtist : ""
                                color: root.textColorSecondary
                                font { family: root.font; pixelSize: root.fontSize - 2 }
                            }
                        }
                    }
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onContainsMouseChanged: Island.hovered = containsMouse
                    onClicked: Island.expanded = !Island.expanded
                }
            }
        }
    }
}