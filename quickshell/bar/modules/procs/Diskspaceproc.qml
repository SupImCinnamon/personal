pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root
    property string space

    Process {
        id: diskSpaceProc
        command: ["sh", "-c", "df -h | awk '{print $3}' | awk 'NR == 2'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: space = this.text.trim()
        }
    }

    Timer {
        interval: 7200000
        running: true
        repeat: true
        onTriggered: diskSpaceProc.running = true
    }
}