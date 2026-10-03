import QtQuick
import QtQuick.Layouts
import "../../bar"
import "../../utils"

Item {
    anchors.fill: parent

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 10
        spacing: 10

        Text {
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: Island.notification ? Icons.bell : ""
            color: "white"
            font.bold: true
            font.family: root.iconFont
        }

        Text {
            anchors.fill: parent
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
            text: Island.notification ? capitalizeFirstLetter(Island.notification.appName) : ""
            color: "white"
            font.bold: true
            font.family: root.font
        }

    }

}
