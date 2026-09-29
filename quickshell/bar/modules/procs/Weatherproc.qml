pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property var weather: []

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl wttr.is/brussels?format=\"%t;%C\" | cut -c 2-"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.weather = this.text.trim().split(";")
        }
    }

    Timer {
        interval: 3600
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }
}