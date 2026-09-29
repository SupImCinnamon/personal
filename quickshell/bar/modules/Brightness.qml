import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire

RowLayout {
    spacing: 7.5
    property real brightness: 100

    Text {
        text: "󱍖"
        font.family: root.font
        font.pixelSize: 20
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }
    Text {
        text: brightness + "%"
        font.family: root.font
        font.pixelSize: root.fontSize
        color: root.textColor
        verticalAlignment: Text.AlignVCenter
        Layout.fillHeight: true
    }

    MouseArea {
        anchors.fill: parent
        onWheel: (wheel) => {
            if (wheel.angleDelta.y > 0) {
                brightness = clamp(brightness + 10, 0, 100);
            } else {
                brightness = clamp(brightness - 10, 0, 100);
            }

            let command = "ddcutil -d 1 setvcp 10 " + brightness + "; ddcutil -d 2 setvcp 10  " + brightness;
            setBrightness.running = false;
            setBrightness.command = ["sh", "-c", command];
            setBrightness.running = true;
        }
    }

    Process {
        id: setBrightness
    }
}

