import Quickshell
import Quickshell.WindowManager
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

RowLayout {
  property color activeColor: root.textColor
  property color inactiveColor: "gray"
  property color activeBackground: "#806491CB"
  property color inactiveBackground: "transparent"

  property var screen: null

  spacing: parent.spacing

  property var projection: screen ? WindowManager.screenProjection(screen) : null

  property var sortedWorkspaces: !projection ? [] : [...projection.windowsets]
    .filter(ws => ws.shouldDisplay !== false)
    .sort((a, b) => {
      var ac = a.coordinates
      var bc = b.coordinates
      var n = Math.max(ac.length, bc.length)
      for (var i = 0; i < n; ++i) {
        var av = i < ac.length ? ac[i] : 0
        var bv = i < bc.length ? bc[i] : 0
        if (av !== bv)
          return av - bv
      }
      return 0
    })

  Repeater {
    model: sortedWorkspaces

    ClippingRectangle {
      required property var modelData

      width: workspaceText.width + 10
      height: 18
      color: modelData.active ? activeBackground : inactiveBackground
      radius: 20

      Text {
        id: workspaceText
        text: {
          if (modelData.name && modelData.name.length > 0)
            return modelData.name
          var c = modelData.coordinates
          return c.length > 0 ? (c[c.length - 1] + 1).toString() : ""
        }
        anchors.centerIn: parent
        verticalAlignment: Text.AlignVCenter
        color: modelData.active ? activeColor : inactiveColor
        font.family: root.font
        font.pixelSize: 13
        font.bold: modelData.active
        Layout.fillHeight: true
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (modelData.canActivate)
            modelData.activate()
        }
      }
    }
  }
}