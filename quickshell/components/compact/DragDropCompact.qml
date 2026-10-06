import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.utils

Item {
    anchors.fill: parent

    Item {
        anchors.fill: parent
        anchors.leftMargin: 10

        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: {
                console.log(Island.dragDropType);
                if (Island.dragDropType == "youtubeVideo") {
                    if (ytDlProc.running) {
                        Icons.cog;
                        return;
                    }
                    Icons.youtubeDownload;
                } else {
                    "";
                }
            }
            color: "white"
            font.bold: true
            font.family: root.iconFont
            font.pixelSize: root.fontSize
        }

        Text {
            anchors.centerIn: parent
            text: {
                if (Island.dragDropType == "youtubeVideo") {
                    if (ytDlProc.running) {
                        "Downloading...";
                    } else {
                        "Drop to download";
                    }
                }
            }
            color: "white"
            font.bold: true
            font.family: root.font
            font.pixelSize: root.fontSize

        }

    }

}
