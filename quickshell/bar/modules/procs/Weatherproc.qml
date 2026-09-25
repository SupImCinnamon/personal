pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string weather

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl wttr.in/brussels?format=\"%t\" | cut -c 2-"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: root.weather = this.text.trim()
        }
    }

    Timer {
        interval: 3600
        running: true
        repeat: true
        onTriggered: weatherProc.running = true
    }
}