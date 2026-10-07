import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.bar
import qs.utils

Item {
    anchors.fill: parent
    property bool lyricsOpen: false
    property var extraHeight: lyricsOpen ? 100 : 0
    onLyricsOpenChanged: if (lyricsOpen) lyricsPage.requestLyrics()
    
    Item {
        anchors.fill: parent
        opacity: lyricsOpen ? 0 : 1
        visible: opacity > 0
        enabled: !lyricsOpen
        Column {
            width: parent.width - 32
            spacing: 15
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.topMargin: 15
            anchors.leftMargin: 15

            Item {
                width: parent.width
                height: 70
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
                        cache: true
                        sourceSize.width: 256
                        sourceSize.height: 256
                        smooth: true
                        mipmap: true
                    }

                }

                Row {
                    id: bars

                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.rightMargin: 10
                    anchors.topMargin: 13
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

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }

                                }

                                Behavior on height {
                                    NumberAnimation {
                                        duration: 50
                                        easing.type: Easing.OutQuad
                                    }

                                }

                            }

                        }

                    }

                }

                Column {
                    anchors.fill: parent
                    anchors.leftMargin: 92
                    anchors.topMargin: 12
                    spacing: 0

                    Text {
                        width: 220
                        elide: Text.ElideRight
                        text: Island.media ? (Island.media.trackTitle) : ""
                        color: "#FFFFFF"
                        font.bold: true
                        font.family: root.font
                        font.pixelSize: root.fontSize
                    }

                    Text {
                        width: 220
                        elide: Text.ElideRight
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
                            "";
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
                        width: (Island.media && Island.media.length > 0) ? (parent.width * (Island.media.position / Island.media.length)) : 0
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

                        Behavior on opacity {
                            NumberAnimation {
                                duration: mediaAnimDuration
                            }

                        }

                    }

                    MouseArea {
                        id: seekArea

                        function seek(mouseX) {
                            const ratio = Math.max(0, Math.min(1, mouseX / width));
                            Island.media.position = ratio * Island.media.length;
                        }

                        anchors.fill: parent
                        anchors.topMargin: -8
                        anchors.bottomMargin: -8
                        enabled: Island.media && Island.media.canSeek && Island.media.length > 0
                        onPressed: (mouse) => {
                            return seek(mouse.x);
                        }
                        onPositionChanged: (mouse) => {
                            if (pressed)
                                seek(mouse.x);

                        }

                        HoverHandler {
                            id: seekHover
                        }

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
                            "";
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
                            if (volume > 0.5)
                                Icons.volumeFull;
                            else if (volume == 0)
                                Icons.volumeMute;
                            else
                                Icons.volumeLow;
                        }
                    }
                    color: root.textColorSecondary
                    font.family: root.iconFont
                    font.pixelSize: 24
                    scale: hvVol.hovered ? 1.12 : 1

                    HoverHandler {
                        id: hvVol
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        enabled: Island.media && Island.media.volumeSupported
                        onWheel: (wheel) => {
                            let volume = Island.media.volume;
                            if (wheel.angleDelta.y > 0)
                                volume = clamp(volume + 0.05, 0, 1);
                            else
                                volume = clamp(volume - 0.05, 0, 1);
                            Island.media.volume = volume;
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: mediaAnimDuration
                            easing.type: Easing.OutQuad
                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                }

                Row {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 30

                    Text {
                        text: Island.media ? Icons.previous : ""
                        color: root.textColor
                        font.family: root.iconFont
                        font.pixelSize: 32
                        scale: hvPrev.hovered ? 1.12 : 1

                        HoverHandler {
                            id: hvPrev
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: Island.media && Island.media.canGoPrevious
                            onClicked: Island.media.previous()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: mediaAnimDuration
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                    Text {
                        text: Island.media && Island.media.playbackState == MprisPlaybackState.Playing ? Icons.pause : Icons.play
                        color: root.textColor
                        font.family: root.iconFont
                        font.pixelSize: 32
                        scale: hvPlay.hovered ? 1.12 : 1

                        HoverHandler {
                            id: hvPlay
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: Island.media && Island.media.canTogglePlaying
                            onClicked: Island.media.togglePlaying()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: mediaAnimDuration
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                    Text {
                        text: Island.media ? Icons.next : ""
                        color: root.textColor
                        font.family: root.iconFont
                        font.pixelSize: 32
                        scale: hvNext.hovered ? 1.12 : 1

                        HoverHandler {
                            id: hvNext
                        }

                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            enabled: Island.media && Island.media.canGoNext
                            onClicked: Island.media.next()
                        }

                        Behavior on scale {
                            NumberAnimation {
                                duration: mediaAnimDuration
                                easing.type: Easing.OutQuad
                            }

                        }

                    }

                }

                Item {
                    Layout.fillWidth: true
                }

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

                    HoverHandler {
                        id: hvLyr
                    }

                    MouseArea {
                        anchors.fill: parent
                        anchors.margins: -6
                        onClicked: {
                            lyricsOpen = !lyricsOpen;
                            console.log(lyricsOpen);
                        }
                    }

                    Behavior on scale {
                        NumberAnimation {
                            duration: mediaAnimDuration
                            easing.type: Easing.OutQuad
                        }

                    }

                }

            }

        }

        Behavior on opacity {
            NumberAnimation {
                duration: 200
            }

        }

    }
    
    Item {
        id: lyricsPage
        anchors.fill: parent
        opacity: lyricsOpen ? 1 : 0
        visible: opacity > 0
        Behavior on opacity { NumberAnimation { duration: 200 } }

        property color fadeColor: "#000000"
        property color accent: "#ffffff"

        readonly property bool canSeek: !!(Island.media && Island.media.canSeek && Lyrics.isSynced)
        readonly property int active: Lyrics.indexAt(Island.media ? Island.media.position * 1000 : 0)
        readonly property string trackKey: Island.media
            ? [Island.media.trackArtist, Island.media.trackTitle, Island.media.trackAlbum].join("|") : ""

        function requestLyrics() {
            if (!Island.media) return
            Lyrics.load(Island.media.trackArtist, Island.media.trackTitle,
                        Island.media.trackAlbum, Island.media.length)
        }
        function seekTo(ms, index) {
            if (!canSeek) return
            Island.media.position = ms / 1000
            resumeTimer.stop()
            lyricsList.userScrolling = false
            lyricsList.follow(index)
        }

        onTrackKeyChanged: if (lyricsOpen) requestLyrics()
        onActiveChanged: if (!lyricsList.userScrolling) lyricsList.follow()
        onVisibleChanged: if (visible) Qt.callLater(lyricsList.follow)
        Component.onCompleted: if (lyricsOpen) requestLyrics()

        Item {
            id: header
            x: 20; y: 14
            width: parent.width - 40; height: 22

            Row {
                spacing: 8
                anchors.verticalCenter: parent.verticalCenter
                Text {
                    text: Icons.lyricsBack
                    color: "white"
                    font.family: root.iconFont
                    font.pixelSize: root.fontSize
                }
                Text {
                    text: "Lyrics"
                    color: "white"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    font.bold: true
                }
            }
            MouseArea { width: 100; height: parent.height; onClicked: lyricsOpen = false }

            Text {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                text: Lyrics.status === "found" ? (Lyrics.isSynced ? "Synced" : "Plain text") : ""
                color: root.textColorSecondary
                font.family: root.font
                font.pixelSize: root.fontSize - 3
            }
        }

        Item {
            id: area
            anchors {
                top: header.bottom; topMargin: 8
                left: parent.left; right: parent.right; bottom: parent.bottom
            }
            clip: true

            ListView {
                id: lyricsList
                anchors.fill: parent
                model: Lyrics.lines
                interactive: false
                cacheBuffer: 20000
                topMargin: height / 2
                bottomMargin: height / 2
                spacing: 2

                property bool userScrolling: false

                function follow(i) {
                    const idx = (i === undefined) ? lyricsPage.active : i
                    if (idx < 0) return
                    const item = itemAtIndex(idx)
                    if (!item) return
                    scrollAnim.stop()
                    scrollAnim.from = contentY
                    scrollAnim.to = item.y + item.height / 2 - height / 2
                    scrollAnim.start()
                }

                onHeightChanged: if (!userScrolling) Qt.callLater(follow)

                Connections {
                    target: Lyrics
                    function onLinesChanged() {
                        scrollAnim.stop()
                        lyricsList.userScrolling = false
                        lyricsList.contentY = -lyricsList.topMargin
                        Qt.callLater(lyricsList.follow)
                    }
                }

                NumberAnimation {
                    id: scrollAnim
                    target: lyricsList
                    property: "contentY"
                    duration: 450
                    easing.type: Easing.OutCubic
                }

                Timer {
                    id: resumeTimer
                    interval: 1000
                    onTriggered: { lyricsList.userScrolling = false; lyricsList.follow() }
                }

                delegate: Item {
                    id: row
                    required property int index
                    required property var modelData

                    readonly property bool current: Lyrics.isSynced && index === lyricsPage.active
                    readonly property int dist: lyricsPage.active < 0 ? 3 : Math.abs(index - lyricsPage.active)

                    width: lyricsList.width
                    height: label.implicitHeight + 20

                    Rectangle {
                        anchors.fill: parent
                        anchors.leftMargin: 8; anchors.rightMargin: 8
                        radius: 12
                        color: root.backgroundColor
                        opacity: ma.containsMouse && ma.enabled ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 120 } }
                    }

                    Text {
                        id: label
                        anchors.centerIn: parent
                        width: parent.width - 64
                        text: row.modelData.text || "♪"
                        wrapMode: Text.WordWrap
                        horizontalAlignment: Text.AlignHCenter
                        font.family: root.font
                        font.pixelSize: 18
                        font.bold: true
                        color: row.current ? lyricsPage.accent : "white"
                        scale: row.current ? 1.08 : 1
                        opacity: !Lyrics.isSynced ? 0.85
                            : row.current ? 1
                            : Math.max(0.2, 0.5 - (row.dist - 1) * 0.1)

                        Behavior on color   { ColorAnimation  { duration: 250 } }
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                        Behavior on scale   { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
                    }

                    MouseArea {
                        id: ma
                        anchors.fill: parent
                        enabled: lyricsPage.canSeek
                        hoverEnabled: true
                        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
                        onClicked: lyricsPage.seekTo(row.modelData.timeMs, row.index)
                    }
                }
            }

            WheelHandler {
                acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
                onWheel: event => {
                    scrollAnim.stop()
                    lyricsList.userScrolling = true
                    const lo = lyricsList.originY - lyricsList.topMargin
                    const hi = lyricsList.originY + lyricsList.contentHeight
                            - lyricsList.height + lyricsList.bottomMargin
                    lyricsList.contentY = Math.max(lo, Math.min(hi,
                        lyricsList.contentY - event.angleDelta.y / 2))
                    resumeTimer.restart()
                }
            }

            Rectangle {
                anchors { top: parent.top; left: parent.left; right: parent.right }
                height: 36
                gradient: Gradient {
                    GradientStop { position: 0; color: lyricsPage.fadeColor }
                    GradientStop { position: 1; color: Qt.rgba(lyricsPage.fadeColor.r, lyricsPage.fadeColor.g, lyricsPage.fadeColor.b, 0) }
                }
            }
            Rectangle {
                anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
                height: 36
                gradient: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(lyricsPage.fadeColor.r, lyricsPage.fadeColor.g, lyricsPage.fadeColor.b, 0) }
                    GradientStop { position: 1; color: lyricsPage.fadeColor }
                }
            }

            Text {
                anchors.centerIn: parent
                visible: Lyrics.lines.length === 0
                color: root.textColorSecondary
                font.family: root.font
                font.pixelSize: root.fontSize
                text: ({
                    loading: "Looking for lyrics…",
                    none: "No lyrics found",
                    instrumental: "♪  Instrumental",
                    error: "Couldn't reach lrclib"
                })[Lyrics.status] ?? ""
            }
        }
    }
}
