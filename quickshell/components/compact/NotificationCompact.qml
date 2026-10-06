import QtQuick
import QtQuick.Layouts
import "../../bar"
import "../../utils"

Item {
    anchors.fill: parent
    anchors.leftMargin: 10
    Text {
        anchors.verticalCenter: parent.verticalCenter
        text: Island.notification ? Icons.bell : ""
        color: "white"
        font.bold: true
        font.family: root.iconFont
    }

    Text {
        anchors.centerIn: parent
        text: Island.notification ? capitalizeFirstLetter(Island.notification.appName) : ""
        color: "white"
        font.bold: true
        font.family: root.font
    }
}