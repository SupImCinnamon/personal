import QtQuick
import QtQuick.Layouts
import qs.bar
import qs.utils

Item {
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 10

        Text {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: {
                console.log(Island.dragDropType);
                if (Island.dragDropType == "youtubeVideo") {
                    if (ytDlProc.running) {
                        Icons.cog;
                        return ;
                    }
                    Icons.youtubeDownload;
                } else {
                    "";
                }
            }
            color: "white"
            font.bold: true
            font.family: root.iconFont
        }

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: {
                if (Island.dragDropType == "youtubeVideo") {
                    if (ytDlProc.running)
                        "Downloading...";
                    else
                        "Drop to download";
                }
            }
            color: "white"
            font.bold: true
            font.family: root.font
        }

    }

}
