import Quickshell
import QtQuick
import Quickshell.Services.Notifications
import Quickshell.Services.Mpris
import qs.bar

ShellRoot {
    id: root

    property string font: "JetbrainsMono Nerd Font"
    property string iconFont: "lucide"
    property int fontSize: 16
    property int fontSizeBig: 28

    property color textColor: "#ffffff"
    property color textColorSecondary: "#aaaaaa"
    property color pillColor: "#000000"
    property color backgroundColor: "#252526"

    readonly property MprisPlayer activePlayer: Mpris.players.values[0].identity == "Spotify" ? Mpris.players.values[0] : null  
    readonly property bool playerAvailable: activePlayer != null
    SystemClock {
        id: clock
        precision: SystemClock.Seconds
    }
    //Clock {}
    DynamicIsland {}
    
    NotificationServer {
        imageSupported: true
        bodyImagesSupported: true
        onNotification: n => {
            n.tracked = true
            //Island.showNotification(n)
        }
    }
    onPlayerAvailableChanged: {
        if (playerAvailable) {
            Island.media = activePlayer;
        } else {
            Island.media = null;
        }
    }

    function clamp(value, min, max) {
        return Math.min(Math.max(value, min), max)
    }

    function capitalizeFirstLetter(val) {
        return String(val).charAt(0).toUpperCase() + String(val).slice(1);
    }
}