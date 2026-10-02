import Quickshell
import QtQuick

Scope {
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            required property var modelData
            screen: modelData

            anchors {
                top: true
                left: true
                right: true
            }
            margins.top: 5
            margins.left: 50
            margins.right: 50

            implicitHeight: 32
            exclusionMode: ExclusionMode.Ignore
            color: "transparent"
            mask: Region {}

            Text {
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                text: Qt.formatTime(clock.date, "hh:mm")
                color: root.textColor
                font { family: root.font; pixelSize: root.fontSize; bold: true }
            }
        }
    }
}