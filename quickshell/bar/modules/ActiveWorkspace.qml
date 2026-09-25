import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

RowLayout {
  // Properties for customization
  property color activeColor: "#cbc9c5"
  property color inactiveColor: "gray"
  property color activeBackground: "#5c696f"
  property color inactiveBackground: "transparent"
  
  // Internal properties
  property var workspaces: []
  
  spacing: parent.spacing
  
  Repeater {
    model: workspaces
    
    Rectangle {
      required property var modelData
      
      width: workspaceText.width + 10
      height: 25
      color: modelData.active ? activeBackground : inactiveBackground
      radius: 0
      
      Text {
        id: workspaceText
        text: modelData.id
        anchors.centerIn: parent
        verticalAlignment: Text.AlignVCenter
        color: modelData.active ? activeColor : inactiveColor
        font.family: root.font
        font.pixelSize: 12
        font.bold: modelData.active
      }
      
      MouseArea {
        anchors.fill: parent
        onClicked: {
          switchWorkspace.command = ["niri", "msg", "action", "focus-workspace", modelData.id.toString()]
          switchWorkspace.running = true
        }
      }
    }
  }
  
  // Get initial workspaces
  Process {
    id: initialProc
    command: ["sh", "-c", "niri msg -j workspaces | jq -r '.[] | \"\\(.id),\\(.is_active)\"'"]
    running: true
    stdout: StdioCollector {
      onStreamFinished: {
        var lines = this.text.trim().split('\n')
        var ws = []
        for (var i = 0; i < lines.length; i++) {
          var parts = lines[i].split(',')
          if (parts.length === 2) {
            ws.push({
              id: parseInt(parts[0]),
              active: parts[1] === 'true'
            })
          }
        }
        ws.sort((a, b) => a.id - b.id)
        workspaces = ws
      }
    }
  }
  
  // Listen to workspace events
  Process {
    id: eventStream
    command: ["sh", "-c", "niri msg -j event-stream | jq --unbuffered -r 'select(.WorkspaceActivated or .WorkspacesChanged) | if .WorkspaceActivated then \"activated,\\(.WorkspaceActivated.id)\" elif .WorkspacesChanged then \"changed\" else empty end'"]
    running: true
    
    stdout: SplitParser {
      splitMarker: "\n"
      onRead: data => {
        if (data && data.length > 0) {
          var trimmed = data.trim()
          if (trimmed.startsWith("activated,")) {
            var id = parseInt(trimmed.split(',')[1])
            // Update active workspace
            var newWorkspaces = workspaces.map(ws => ({
              id: ws.id,
              active: ws.id === id
            }))
            workspaces = newWorkspaces
          } else if (trimmed === "changed") {
            // Refresh all workspaces
            initialProc.running = true
          }
        }
      }
    }
  }
  
  // Process to switch workspaces
  Process {
    id: switchWorkspace
    running: false
  }
}