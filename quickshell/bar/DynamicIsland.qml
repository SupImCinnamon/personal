import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Services.Mpris
import Quickshell.Wayland
import qs.utils

Scope {
    id: barRoot
    property int barCount: 6
    property int mediaAnimDuration: 150
    property bool lyricsOpen: false
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

            WlrLayershell.layer: Island.notification ? WlrLayer.Overlay : WlrLayer.Top

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
            Rectangle {
                id: pill
                x: (parent.width - width) / 2

                readonly property var layout: Island.layouts[Island.primary]
                readonly property size target: Island.currentSize

                function viewFor(activity, kind) {
                    switch (activity + ":" + kind) {
                    case "idle:compact":     return idleCompact
                    case "idle:expanded":    return idleExpanded
                    case "notification:compact":    return notifCompact
                    case "notification:expanded":   return notifExpanded
                    case "media:compact":    return mediaCompact
                    case "media:expanded":   return mediaExpanded
                    case "dragDrop:compact":   return dragDropCompact
                    case "dragDrop:expanded":   return dragDropExpanded

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
                    onContainsMouseChanged: Island.hovered = containsMouse
                    onClicked: Island.expanded = !Island.expanded
                }

                Loader {
                    anchors.fill: parent
                    sourceComponent: pill.viewFor(Island.primary, Island.expanded ? "expanded" : "compact") ?? pill.viewFor("idle", Island.expanded ? "expanded" : "compact")
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
                            anchors.leftMargin: 10
                            spacing: 10
                            Text {
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Island.notification ? Icons.bell : ""
                                color: "white"; font.bold: true
                                font.family: root.iconFont
                            }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: Island.notification ? capitalizeFirstLetter(Island.notification.appName) : ""
                                color: "white";
                                font.bold: true
                                font.family: root.font
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
                            spacing: 2

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
                        Item {
                            anchors.fill: parent
                            opacity: barRoot.lyricsOpen ? 0 : 1
                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                            Column {
                                width: parent.width - 32
                                spacing: 15
                                anchors.top: parent.top
                                anchors.left: parent.left
                                anchors.topMargin: 15
                                anchors.leftMargin: 15
                                RowLayout {
                                    width: parent.width
                                    spacing: 0
                                    ClippingRectangle {
                                        width: 64
                                        height: 64
                                        radius: 4
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        Image {
                                            width: 64
                                            height: 64
                                            fillMode: Image.PreserveAspectCrop
                                            source: Island.media ? Island.media.trackArtUrl : ""
                                            asynchronous: false
                                            cache: false
                                        }
                                    }
                                    Row {
                                        id: bars
                                        anchors.right: parent.right
                                        anchors.top: parent.top
                                        anchors.rightMargin: 10
                                        anchors.topMargin: 10

                                        height: 22
                                        spacing: 2

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
                                    Column {
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.leftMargin: 92
                                        anchors.topMargin: 9
                                        Text {
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                            text: Island.media ? (Island.media.trackTitle) : ""
                                            color: "#FFFFFF"
                                            font.bold: true
                                            font.family: root.font
                                            font.pixelSize: root.fontSize
                                        }
                                        Text {
                                            width: parent.width
                                            elide: Text.ElideRight
                                            maximumLineCount: 3
                                            wrapMode: Text.Wrap
                                            text: Island.media ? (Island.media.trackArtist || "") : ""
                                            color: root.textColorSecondary
                                            font.family: root.font
                                        }
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    spacing: 10
                                    anchors.left: parent.left
                                    anchors.right: parent.right
                                    anchors.leftMargin: 9
                                    anchors.rightMargin: 7

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        elide: Text.ElideLeft
                                        text: {
                                            if (Island.media) {
                                                var totalSeconds = Island.media.position;
                                                var minutes = Math.floor(totalSeconds / 60);
                                                var seconds = Math.floor(totalSeconds % 60);
                                                minutes + ":" + String(seconds).padStart(2, '0');
                                            } else {
                                                ""
                                            }
                                        }
                                        color: root.textColorSecondary
                                        font.family: root.font
                                        font.pixelSize: root.fontSize - 3
                                    }

                                    Item {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 9
                                        Layout.alignment: Qt.AlignVCenter

                                        Rectangle {
                                            anchors.fill: parent
                                            anchors.bottomMargin: 2
                                            color: "#252526"
                                            radius: 3
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom

                                            anchors.bottomMargin: 2

                                            width: (Island.media && Island.media.length > 0)
                                                ? (parent.width * (Island.media.position / Island.media.length))
                                                : 0

                                            color: root.textColorSecondary
                                            radius: 3
                                        }

                                        Rectangle {
                                            anchors.left: parent.left
                                            anchors.top: parent.top
                                            anchors.bottom: parent.bottom
                                            anchors.bottomMargin: 2

                                            width: Math.max(0, Math.min(parent.width, seekHover.point.position.x))
                                            color: Qt.lighter(root.textColorSecondary, 1.6)
                                            radius: 3
                                            opacity: seekHover.hovered && seekArea.enabled ? 1 : 0

                                            Behavior on opacity { NumberAnimation { duration: mediaAnimDuration } }
                                        }

                                        MouseArea {
                                            id: seekArea
                                            HoverHandler { id: seekHover }

                                            anchors.fill: parent
                                            anchors.topMargin: -8
                                            anchors.bottomMargin: -8
                                            enabled: Island.media && Island.media.canSeek && Island.media.length > 0

                                            function seek(mouseX) {
                                                const ratio = Math.max(0, Math.min(1, mouseX / width));
                                                Island.media.position = ratio * Island.media.length;
                                            }
                                            onPressed: mouse => seek(mouse.x)
                                            onPositionChanged: mouse => { if (pressed) seek(mouse.x) }
                                        }
                                    }

                                    Text {
                                        Layout.alignment: Qt.AlignVCenter
                                        elide: Text.ElideRight
                                        text: {
                                            if (Island.media) {
                                                var totalSeconds = Island.media.length;
                                                var minutes = Math.floor(totalSeconds / 60);
                                                var seconds = Math.floor(totalSeconds % 60);
                                                minutes + ":" + String(seconds).padStart(2, '0');
                                            } else {
                                                ""
                                            }
                                        }
                                        color: root.textColorSecondary
                                        font.family: root.font
                                        font.pixelSize: root.fontSize - 3
                                    }
                                }

                                RowLayout {
                                    width: parent.width
                                    height: 40
                                    spacing: 0

                                    Text {
                                        Layout.preferredWidth: 24
                                        Layout.leftMargin: 15
                                        Layout.alignment: Qt.AlignVCenter
                                        horizontalAlignment: Text.AlignLeft
                                        text: {
                                            if (Island.media) {
                                                let volume = Island.media.volume;
                                                if(volume > 0.5) {
                                                    Icons.volumeFull
                                                } else if (volume == 0) {
                                                    Icons.volumeMute
                                                } else {
                                                    Icons.volumeLow
                                                }
                                            }
                                        }
                                        color: root.textColorSecondary
                                        font.family: root.iconFont
                                        font.pixelSize: 24

                                        scale: hvVol.hovered ? 1.12 : 1
                                        Behavior on scale { NumberAnimation { duration: mediaAnimDuration; easing.type: Easing.OutQuad } }
                                        HoverHandler { id: hvVol }

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            enabled: Island.media && Island.media.volumeSupported
                                            onWheel: (wheel) => {
                                                let volume = Island.media.volume;
                                                if (wheel.angleDelta.y > 0) {
                                                    volume = clamp(volume + 0.05, 0, 1);
                                                } else {
                                                    volume = clamp(volume - 0.05, 0, 1);
                                                }
                                                
                                                Island.media.volume = volume;
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Row {
                                        Layout.alignment: Qt.AlignVCenter
                                        spacing: 30

                                        Text {
                                            text: Island.media ? Icons.previous : ""
                                            color: root.textColor
                                            font.family: root.iconFont
                                            font.pixelSize: 32

                                            scale: hvPrev.hovered ? 1.12 : 1
                                            Behavior on scale { NumberAnimation { duration: mediaAnimDuration; easing.type: Easing.OutQuad } }
                                            HoverHandler { id: hvPrev }

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                    enabled: Island.media && Island.media.canGoPrevious
                                                onClicked: Island.media.previous()
                                            }
                                        }
                                        Text {
                                            text: Island.media && Island.media.playbackState == MprisPlaybackState.Playing ? Icons.pause : Icons.play
                                            color: root.textColor
                                            font.family: root.iconFont
                                            font.pixelSize: 32

                                            scale: hvPlay.hovered ? 1.12 : 1
                                            Behavior on scale { NumberAnimation { duration: mediaAnimDuration; easing.type: Easing.OutQuad } }
                                            HoverHandler { id: hvPlay }

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                    enabled: Island.media && Island.media.canTogglePlaying
                                                onClicked: Island.media.togglePlaying()
                                            }
                                        }
                                        Text {
                                            text: Island.media ? Icons.next : ""
                                            color: root.textColor
                                            font.family: root.iconFont
                                            font.pixelSize: 32

                                            scale: hvNext.hovered ? 1.12 : 1
                                            Behavior on scale { NumberAnimation { duration: mediaAnimDuration; easing.type: Easing.OutQuad } }
                                            HoverHandler { id: hvNext }

                                            MouseArea {
                                                anchors.fill: parent
                                                anchors.margins: -6
                                                    enabled: Island.media && Island.media.canGoNext
                                                onClicked: Island.media.next()
                                            }
                                        }
                                    }

                                    Item { Layout.fillWidth: true }

                                    Text {
                                        Layout.preferredWidth: 24
                                        Layout.rightMargin: 12
                                        Layout.topMargin: 3
                                        Layout.alignment: Qt.AlignVCenter
                                        horizontalAlignment: Text.AlignRight
                                        text: Island.media ? Icons.lyrics : ""
                                        color: root.textColorSecondary
                                        font.family: root.iconFont
                                        font.pixelSize: 24

                                        scale: hvLyr.hovered ? 1.12 : 1
                                        Behavior on scale { NumberAnimation { duration: mediaAnimDuration; easing.type: Easing.OutQuad } }
                                        HoverHandler { id: hvLyr }

                                        MouseArea {
                                            anchors.fill: parent
                                            anchors.margins: -6
                                            onClicked: {
                                                barRoot.lyricsOpen = !barRoot.lyricsOpen;
                                                console.log(barRoot.lyricsOpen);
                                            }
                                        }
                                    }
                                }
                            }
                        }
                                /*
                        Item {
                            anchors.fill: parent
                            opacity: barRoot.lyricsOpen ? 1 : 0
                            Behavior on opacity {
                                NumberAnimation { duration: 200 }
                            }
                            Column {
                                anchors.left: parent.left
                                anchors.top: parent.top
                                anchors.leftMargin: 20
                                anchors.topMargin: 15
                                spacing: 12
                                Rectangle {
                                    width: 85
                                    height: 20
                                    color: "transparent"
                                    RowLayout {
                                        spacing: 10
                                        Text {
                                            Layout.alignment: Qt.AlignVCenter
                                            text: Icons.lyricsBack
                                            color: "white"
                                            font {
                                                family: root.iconFont
                                                pixelSize: root.pixelSize
                                            }
                                        }
                                        Text {
                                            verticalAlignment: Text.AlignVCenter
                                            horizontalAlignment: Text.AlignHCenter
                                            text: "Lyrics"
                                            color: "white"
                                            font {
                                                family: root.font
                                                pixelSize: root.pixelSize
                                            }
                                        }
                                    }
                                }
                                Rectangle {
                                    width: 320
                                    height: 450
                                    color: "#11111b"
                                    radius: 12

                                    property int currentTrackTimeMs: 6000

                                    onCurrentTrackTimeMsChanged: {
                                        for (var i = 0; i < lyricsModel.count; i++) {
                                            if (lyricsModel.get(i).timeMs <= currentTrackTimeMs && 
                                            (i === lyricsModel.count - 1 || lyricsModel.get(i + 1).timeMs > currentTrackTimeMs)) {
                                                
                                                if (lyricsList.currentIndex !== i) {
                                                    lyricsList.currentIndex = i;
                                                    lyricsList.positionViewAtIndex(i, ListView.Center);
                                                }
                                                break;
                                            }
                                        }
                                    }

                                    ListModel {
                                        id: lyricsModel
                                        ListElement { timeMs: 0; text: "Instrumental Intro" }
                                        ListElement { timeMs: 5000; text: "First line of the song" }
                                        ListElement { timeMs: 9500; text: "Second line of the song" }
                                    }

                                    ListView {
                                        id: lyricsList
                                        anchors.fill: parent
                                        anchors.margins: 15
                                        model: lyricsModel
                                        clip: true
                                        focus: true

                                        highlightMoveDuration: 300
                                        highlightMoveVelocity: -1

                                        delegate: Item {
                                            width: lyricsList.width
                                            height: lyricText.implicitHeight + 16

                                            property bool isCurrent: ListView.isCurrentItem

                                            Text {
                                                id: lyricText
                                                width: parent.width
                                                text: model.text
                                                font.pointSize: isCurrent ? 16 : 13
                                                font.bold: isCurrent
                                                color: isCurrent ? "#f5c2e7" : "#a6adc8"
                                                wrapMode: Text.WordWrap
                                                horizontalAlignment: Text.AlignHCenter

                                                Behavior on color { ColorAnimation { duration: 200 } }
                                                Behavior on font.pointSize { NumberAnimation { duration: 200 } }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                                */
                    }
                }

                Component {
                    id: dragDropCompact
                    Item {
                        anchors.fill: parent
                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            spacing: 10
                            Text {
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: {
                                    console.log(Island.dragDropType)
                                    if(Island.dragDropType == "youtubeVideo") {
                                        if(ytDlProc.running) {
                                            Icons.cog
                                            return;
                                        }
                                        Icons.youtubeDownload
                                    } else {
                                        ""
                                    }
                                }
                                color: "white"; font.bold: true
                                font.family: root.iconFont
                            }
                            Text {
                                anchors.fill: parent
                                verticalAlignment: Text.AlignVCenter
                                horizontalAlignment: Text.AlignHCenter
                                text: {
                                    if(Island.dragDropType == "youtubeVideo") {
                                        if(ytDlProc.running) {
                                            "Downloading..."
                                        } else {
                                            "Drop to download"
                                        }

                                    }
                                }
                                color: "white";
                                font.bold: true
                                font.family: root.font
                            }
                        }
                    }
                }

                Component {
                    id: dragDropExpanded
                    Text{
                        
                    }
                }
            }

            Rectangle {
                id: bubble
                readonly property bool shown:
                    (Island.secondary !== ""
                    && !Island.expanded
                    && pill.viewFor(Island.secondary, "bubble") !== null) || true

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