import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io

RowLayout {
    id: controlCenterTrigger
    width: 50
    height: 50

    Rectangle {
        anchors.fill: parent
        color: hoverArea.containsMouse ? "rgba(255,255,255,0.1)" : "transparent"

        Text {
            anchors.centerIn: parent
            text: "⚙"
            font.pixelSize: 20
        }
    }

    MouseArea {
        id: hoverArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (controlCenter.visible) {
                controlCenter.visible = false
            } else {
                // Position relative to trigger
                var g = controlCenterTrigger.mapToGlobal(0, 0)
                controlCenter.visible = true
                controlCenter.raise() // bring to front
            }
        }
    }

    // Floating popup as a top-level window


  PopupWindow {
    anchor.window: toplevel
    anchor.rect.x: parentWindow.width / 2 - width / 2
    anchor.rect.y: parentWindow.height
    width: 500
    height: 500
    visible: true
  }
}
