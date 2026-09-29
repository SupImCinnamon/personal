import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Notifications

PanelWindow {
    id: notifElement

    property string notifAppName: emptyText
    property string notifSummary: emptyText
    property string notifBody: emptyText
    
    WlrLayershell.layer: WlrLayer.Overlay
    exclusionMode: ExclusionMode.Ignore
    
    anchors {
        top: true
        right: true
    }
    margins {
        top: 10
        right: 10
    }

    width: 250
    height: 100
    color: "transparent"
    BackgroundEffect.blurRegion: Region { 
        item: content
        radius: 12 
    }
    visible: false

    function displayNotification(title, summary, body) {
        notifAppName = title || "Notification"
        notifSummary = summary || "No summary"
        notifBody = body || "Empty notification"
        notifElement.visible = true;
        console.log("hope this worked");
        dismissTimer.restart();
    }
    

    Timer {
        id: dismissTimer
        interval: 4000
        onTriggered: notifElement.visible = false
    }

    ClippingRectangle {
        id: content
        anchors.fill: parent
        color: root.windowColor

        bottomLeftRadius: 12
        bottomRightRadius: 12
        topLeftRadius: 12
        topRightRadius: 12

        border.width: 2
        border.color: "#FFFFFF"
        

        Text {
            text: notifAppName + " - " + notifSummary + " | " + notifBody
            leftPadding: 2
            font.family: root.font
            font.pixelSize: root.fontSize
            color: root.textColor
            wrapMode: Text.WrapAnywhere
            width: parent.width - 12
        }
    }
}