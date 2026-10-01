import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell.Services.Pipewire
import "../../components"

RowLayout {
    spacing: 5
    property var defaultAudioSink: Pipewire.defaultAudioSink
    property real volume: defaultAudioSink?.audio?.volume ?? 0.0
    property real volumeRounded: Math.round((defaultAudioSink?.audio?.volume * 100))
    property real oldVolume: 0


    PwObjectTracker {
        objects: defaultAudioSink ? [defaultAudioSink] : []
    }

    Text {
        text: {
            if(volumeRounded >= 80) {
                ""
            } else if (volumeRounded >= 40 && volumeRounded < 80) {
                ""
            } else if (volumeRounded < 40 && volumeRounded > 0) {
                ""
            } else {
                ""
            }
        }
        font.family: root.font
        font.pixelSize: root.iconSize - 2
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }
    Text {
        text: volumeRounded + "%"
        font.family: root.font
        font.pixelSize: root.fontSize
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        onClicked: (mouse) => {
            if(mouse.button == Qt.MiddleButton) {
                if (volume == 0) {
                    volume = oldVolume;
                    defaultAudioSink.audio.volume = volume;
                    volumeRounded = Math.round((volume * 100))
                    return;
                }
                oldVolume = volume;
                volume = 0;
                defaultAudioSink.audio.volume = volume;
                volumeRounded = Math.round((volume * 100))
            } else {
                mixer.visible = !mixer.visible;
            }
        }
        onWheel: (wheel) => {
            if (!defaultAudioSink || !defaultAudioSink.audio) return;

            let newVolume = volume;
            if (wheel.angleDelta.y > 0) {
                volume = clamp(volume + 0.05, 0, 1);
            } else {
                volume = clamp(volume - 0.05, 0, 1);
            }
            
            defaultAudioSink.audio.volume = newVolume;
            volumeRounded = Math.round((volume * 100))
        }
    }

    PopupWindow {
        id: mixer
        anchor.window: barWindow
        anchor.rect.x: (parentWindow.width / 2 - width / 2) + 700
        anchor.rect.y: parentWindow.height + 9
        implicitWidth: 500
        implicitHeight: 250
        color: "transparent"
        BackgroundEffect.blurRegion: Region { 
            item: content
            radius: 12 
        }
        visible: false

        Rectangle {
            id: content
            anchors.fill: parent
            color: root.windowColorSecondary

            bottomLeftRadius: 12
            bottomRightRadius: 12
            topLeftRadius: 12
            topRightRadius: 12

            border.color: "#ffffff"
            border.width: 2

            ScrollView {
                anchors.fill: parent
                contentWidth: availableWidth
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    PwNodeLinkTracker {
                        id: linkTracker
                        node: Pipewire.defaultAudioSink
				    }

                    MixerElement {
                        node: Pipewire.defaultAudioSink
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        color: "#FFFFFF"
                        implicitHeight: 1
                    }
                    Repeater {
                        model: linkTracker.linkGroups

                        MixerElement {
                            required property PwLinkGroup modelData
                            node: modelData.source
                        }
				    }
                }
            }
        }
    }
}

