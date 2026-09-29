import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Widgets
import QtQuick
import QtQuick.Layouts

PanelWindow {
    id: popup

    property string pendingName: ""
    property string pendingUrl: ""
    property int currentIndex: 0
    property string page: "confirm"
    property bool urlFromClipboard: false
    property string format: ""
    property string quality: "Best (recommended)"
    property string nameReturn: "format"
    property int optionCount: 2
    property var qualityOptions: ["Best (recommended)", "1080p", "720p", "480p"]
    property string shortName: pendingName.length > 55 ? pendingName.slice(0, 52) + "…" : pendingName
    readonly property string scriptPath: "/home/cinnamon/dev/personal/scripts/ytdl-cinnamon.py"

    visible: false
    implicitWidth: 460
    implicitHeight: page === "quality" ? 280 : 220
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore

    BackgroundEffect.blurRegion: Region {
        item: card
        radius: 12
    }

    function open() {
        if (detectProc.running)
            return
        page = "confirm"
        pendingName = ""
        pendingUrl = ""
        format = ""
        optionCount = 2
        currentIndex = 0
        detectProc.running = true
    }

    function close() {
        visible = false
    }

    function confirm() {
        if (pendingUrl === "")
            pendingUrl = "ytsearch1:" + pendingName
        gotoFormat()
    }

    function decline() {
        gotoUrl()
    }

    function gotoUrl() {
        page = "url"
        urlFromClipboard = false
        urlInput.text = ""
        pasteProc.running = true
    }

    function submitUrl() {
        const t = urlInput.text.trim()
        if (t === "")
            return
        pendingUrl = t
        gotoFormat()
    }

    function backToConfirm() {
        page = "confirm"
        optionCount = 2
        currentIndex = 0
    }

    function gotoFormat() {
        page = "format"
        optionCount = 2
        currentIndex = 0
    }

    function selectFormat() {
        if (currentIndex === 0) {
            format = "mp3"
            gotoName("format")
        } else {
            format = "mp4"
            gotoQuality()
        }
    }

    function gotoQuality() {
        page = "quality"
        quality = "Best (recommended)"
        optionCount = 4
        currentIndex = 0
    }

    function selectQuality() {
        quality = qualityOptions[currentIndex]
        gotoName("quality")
    }

    function gotoName(from) {
        nameReturn = from
        page = "name"
        nameInput.text = ""
    }

    function download() {
        const args = ["python3", scriptPath, "--url", pendingUrl, "--format", format]
        if (format === "mp4")
            args.push("--quality", quality)
        args.push("--name", nameInput.text.trim())
        Quickshell.execDetached(args)
        close()
    }

    Process {
        id: detectProc
        command: ["python3", popup.scriptPath, "--detect-json"]
        stdout: StdioCollector {
            id: detectOut
        }
        onExited: {
            let d = {}
            try {
                d = JSON.parse(detectOut.text)
            } catch (e) {
                d = {}
            }
            if (!d.videoname) {
                Quickshell.execDetached(["python3", popup.scriptPath])
                return
            }
            popup.pendingName = d.videoname
            popup.pendingUrl = d.url || ""
            popup.currentIndex = 0
            popup.visible = true
        }
    }

    Process {
        id: pasteProc
        command: ["wl-paste"]
        stdout: StdioCollector {
            id: pasteOut
        }
        onExited: {
            const m = /https?:\/\/(www\.|m\.|music\.)?(youtube\.com\/(watch\?[^\s"']+|shorts\/[^\s"']+|live\/[^\s"']+)|youtu\.be\/[^\s"']+)/.exec(pasteOut.text || "")
            if (m && popup.page === "url" && urlInput.text === "") {
                urlInput.text = m[0]
                popup.urlFromClipboard = true
            }
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: root.windowColor
        topLeftRadius: 12
        topRightRadius: 12
        bottomLeftRadius: 12
        bottomRightRadius: 12
        border.width: 3
        border.color: "#FFFFFF"

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 1

            Text {
                Layout.fillWidth: true
                visible: page === "confirm"
                text: "Found YouTube video from Firefox, download it ?"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                color: root.textColor
                wrapMode: Text.WrapAnywhere
                width: parent.width - 12
            }

            Text {
                Layout.fillWidth: true
                visible: page === "url"
                text: "Paste YouTube URL"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                color: root.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                visible: page === "url"
                color: "transparent"
                border.width: 1
                border.color: "#FFFFFF"
                TextInput {
                    id: urlInput
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.textColor
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    focus: popup.page === "url"
                    clip: true
                    onAccepted: popup.submitUrl()
                    onTextEdited: popup.urlFromClipboard = false
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            popup.backToConfirm()
                            event.accepted = true
                        }
                    }
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: Text.AlignVCenter
                    text: "Paste YouTube URL"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: root.textColorSecondary
                    visible: urlInput.text === ""
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "confirm"
                color: popup.currentIndex === 0 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: "Yes"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 0 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 0
                    onClicked: popup.confirm()
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "confirm"
                color: popup.currentIndex === 1 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: "No"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 1 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 1
                    onClicked: popup.decline()
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page === "format"
                text: "Choose format"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                color: root.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "format"
                color: popup.currentIndex === 0 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: "mp3"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 0 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 0
                    onClicked: { popup.currentIndex = 0; popup.selectFormat() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "format"
                color: popup.currentIndex === 1 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: "mp4"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 1 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 1
                    onClicked: { popup.currentIndex = 1; popup.selectFormat() }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page === "quality"
                text: "Choose quality"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                color: root.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "quality"
                color: popup.currentIndex === 0 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: popup.qualityOptions[0]
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 0 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 0
                    onClicked: { popup.currentIndex = 0; popup.selectQuality() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "quality"
                color: popup.currentIndex === 1 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: popup.qualityOptions[1]
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 1 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 1
                    onClicked: { popup.currentIndex = 1; popup.selectQuality() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "quality"
                color: popup.currentIndex === 2 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: popup.qualityOptions[2]
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 2 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 2
                    onClicked: { popup.currentIndex = 2; popup.selectQuality() }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 30
                radius: 6
                visible: page === "quality"
                color: popup.currentIndex === 3 ? "#FFFFFF" : "transparent"
                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    x: 10
                    text: popup.qualityOptions[3]
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: popup.currentIndex === 3 ? "#1a1b26" : root.textColor
                }
                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onEntered: popup.currentIndex = 3
                    onClicked: { popup.currentIndex = 3; popup.selectQuality() }
                }
            }

            Text {
                Layout.fillWidth: true
                visible: page === "name"
                text: "Output name"
                font.family: root.font
                font.pixelSize: root.fontSize + 1
                color: root.textColor
            }

            Rectangle {
                Layout.fillWidth: true
                height: 34
                radius: 6
                visible: page === "name"
                color: "transparent"
                border.width: 1
                border.color: "#FFFFFF"
                TextInput {
                    id: nameInput
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: TextInput.AlignVCenter
                    color: root.textColor
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    focus: popup.page === "name"
                    clip: true
                    onAccepted: popup.download()
                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            popup.page = popup.nameReturn
                            event.accepted = true
                        }
                    }
                }
                Text {
                    anchors.fill: parent
                    anchors.margins: 8
                    verticalAlignment: Text.AlignVCenter
                    text: "empty = video title"
                    font.family: root.font
                    font.pixelSize: root.fontSize
                    color: root.textColorSecondary
                    visible: nameInput.text === ""
                }
            }

            Text {
                Layout.fillWidth: true
                Layout.topMargin: 4
                text: page === "url" ? (urlFromClipboard ? "URL autodetected from clipboard\nEnter confirms, Esc goes back" : "Enter confirms — Esc goes back") : (page === "format" ? "Enter selects — Esc goes back" : (page === "quality" ? "Enter selects — Esc goes back" : (page === "name" ? "Empty = video title — Enter downloads, Esc goes back" : ("Video found : " + (popup.shortName !== "" ? "\n" + popup.shortName : "\n(no URL in history — will search)")))))
                font.family: root.font
                font.pixelSize: root.fontSize - 2
                color: root.textColorSecondary
                wrapMode: Text.WrapAnywhere
                width: card.width - 10
                elide: Text.ElideMiddle
                maximumLineCount: 2
            }
        }
    }

    Item {
        anchors.fill: parent
        focus: page !== "url" && page !== "name"
        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                if (page === "confirm")
                    popup.close()
                else if (page === "quality")
                    popup.gotoFormat()
                else
                    popup.backToConfirm()
                event.accepted = true
            } else if ((event.key === Qt.Key_Up || event.key === Qt.Key_Down) && page !== "url") {
                popup.currentIndex = (popup.currentIndex + (event.key === Qt.Key_Down ? 1 : popup.optionCount - 1)) % popup.optionCount
                event.accepted = true
            } else if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && page !== "url") {
                if (page === "confirm") {
                    if (popup.currentIndex === 0)
                        popup.confirm()
                    else
                        popup.decline()
                } else if (page === "format") {
                    popup.selectFormat()
                } else if (page === "quality") {
                    popup.selectQuality()
                }
                event.accepted = true
            } else if (event.key === Qt.Key_Y && page === "confirm") {
                popup.confirm()
                event.accepted = true
            } else if (event.key === Qt.Key_N && page === "confirm") {
                popup.decline()
                event.accepted = true
            }
        }
    }
}
