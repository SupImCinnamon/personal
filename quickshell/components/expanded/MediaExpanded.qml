import QtQuick
import QtQuick.Layouts
import Quickshell.Widgets
import Quickshell.Services.Mpris
import qs.bar
import qs.utils

Item {
    anchors.fill: parent

    Item {
        anchors.fill: parent
        opacity: barRoot.lyricsOpen ? 0 : 1

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
                        cache: false
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

                        elide: Text.ElideRight
                        text: Island.media ? (Island.media.trackTitle) : ""
                        color: "#FFFFFF"
                        font.bold: true
                        font.family: root.font
                        font.pixelSize: root.fontSize
                    }

                    Text {

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
                            barRoot.lyricsOpen = !barRoot.lyricsOpen;
                            console.log(barRoot.lyricsOpen);
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
