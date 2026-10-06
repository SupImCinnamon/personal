import QtQuick
import Quickshell.Widgets
import "../../bar"

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
            cache: true
            smooth: true
            mipmap: true
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

}
