import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import qs.utils

// A minimal file browser living inside the Island.
// `req` is the request object from the sidecar (see island_portal.py).
FocusScope {
    id: filePicker
    required property var req
    signal accepted(var uris)
    signal cancelled()

    readonly property bool isSave: req.type === "save"
    readonly property bool dirMode: req.directory === true
    property var picked: []          // selected file:// URI strings
    property int filterIndex: 0
    property bool askOverwrite: false

    // Portal filters: [[label, [[0, glob], [1, mime]]], ...]
    // This sketch only honours globs; MIME entries fall back to "*".
    function globsFor(i) {
        const f = req.filters || []
        if (f.length === 0 || i >= f.length) return ["*"]
        const g = f[i][1].filter(p => p[0] === 0).map(p => p[1])
        return g.length ? g : ["*"]
    }

    function confirm() {
        if (isSave) {
            const name = nameField.text.trim()
            if (!name) return
            const uri = dir.folder.toString() + "/" + encodeURIComponent(name)
            if (dir.indexOf(uri) >= 0 && !askOverwrite) { askOverwrite = true; return }
            accepted([uri])
        } else if (dirMode) {
            accepted(picked.length ? picked : [dir.folder.toString()])
        } else if (picked.length) {
            accepted(picked)
        }
    }

    Keys.onReturnPressed: confirm()
    Keys.onEscapePressed: cancelled()
    Component.onCompleted: forceActiveFocus()

    FolderListModel {
        id: dir
        folder: req.current_folder ? "file://" + req.current_folder
                                   : "file://" + Quickshell.env("HOME")
        showDirs: true
        showFiles: !filePicker.dirMode
        showDirsFirst: true
        showDotAndDotDot: false
        nameFilters: filePicker.isSave ? ["*"] : filePicker.globsFor(filePicker.filterIndex)
        Component.onCompleted: console.log("[chooser] start folder:", folder,
                                   "HOME:", Quickshell.env("HOME"),
                                   "current_folder:", filePicker.req.current_folder)
    }


        // Dropping a file from any app satisfies the dialog.
        /*
        DropArea {
            anchors.fill: parent
            keys: ["text/uri-list"]
            enabled: !filePicker.isSave && !filePicker.dirMode
            onDropped: drop => {
                if (drop.hasUrls)
                    filePicker.accepted(drop.urls.map(u => u.toString()))
            }
        }
        */

    Column {
        id: mainCol
        property int spacerWidth: 1
        anchors.fill: parent
        anchors.margins: 0
        spacing: 10
        Item {
            width: parent.width
            height: 40
            Row {

                width: parent.width
                height: parent.height
                spacing: 10
                Item {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    width: parent.width
                    height: parent.height
                    Row {
                        spacing: 10
                        Image {
                            width: 40
                            height: 40
                            source: Quickshell.iconPath("discord")
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: false
                            cache: true
                            smooth: true
                            mipmap: true
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: "Discord"
                                //text: req.title + (req.app_id ? "  ·  " + req.app_id : "")
                                color: root.textColor
                                font {
                                    family: root.font
                                    pixelSize: root.fontSize - 2
                                    bold: true
                                }
                            }
                            Text {
                                text: {
                                    if(filePicker.isSave) {
                                        "Save File"
                                    } else {
                                        "Open File"
                                    }
                                }
                                //text: req.title + (req.app_id ? "  ·  " + req.app_id : "")
                                color: Qt.lighter(root.backgroundColor, 4)
                                font {
                                    family: root.font
                                    pixelSize: root.fontSize - 4
                                    bold: true
                                }
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
                Item {
                    anchors.centerIn: parent
                    width: 500
                    height: 35
                    TextField {
                        width: parent.width
                        height: 35
                        leftPadding: 40 
                        placeholderText: "Search files, or type a path..."
                        color: root.textColor
                        Text {
                            text: Icons.search
                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.lighter(root.backgroundColor, 4)
                            font {
                                family: root.iconFont
                                pixelSize: root.fontSize
                            }
                        }
                        background: Rectangle {
                            radius: 8          // Adjust the corner radius here
                            color: root.backgroundColor     // Background color
                            border.color: parent.activeFocus ? Qt.lighter(root.accentBackground, 4) : root.backgroundColor
                            border.width: parent.activeFocus ? 1 : 0
                        }
                        font {
                            family: root.font
                            pixelSize: root.fontSize - 4
                        }
                    }
                }
            }
        }
        /*
        Row {
            //Button { text: "↑"; onClicked: dir.folder = dir.parentFolder }
            Text {
                text: dir.folder.toString().replace("file://", "")
                color: "#aaa";
                elide: Text.ElideLeft;
                font {
                    family: root.font
                    pixelSize: root.fontSize
                }
            }
            ComboBox {
                visible: !filePicker.isSave && (req.filters || []).length > 1
                model: (req.filters || []).map(f => f[0])
                onActivated: i => filePicker.filterIndex = i
            }
        }
        */
        Rectangle {
            width: parent.width
            height: mainCol.spacerWidth
            anchors.left: parent.left
            color: root.backgroundColor
        }
        Item {
            width: parent.width
            height: 350
            ListView {
                id: categories
                width: 200
                height: 350
                spacing: 0
                clip: true

                property var selectedCat: "recents"
                property var entries: [
                    // ---------- Top section ----------
                    { key: "mycomputer", label: "My Computer", icon: Icons.computer,  path: "file:///" },
                    { key: "warehouse",  label: "Warehouse",   icon: Icons.warehouse, path: "file://" + Quickshell.env("HOME") + "/.config/quickshell/warehouse" },
                    { key: "recents",    label: "Recents",     icon: Icons.recent,   path: "" },

                    // ---------- "Places" header ----------
                    { key: "---places---" },

                    // ---------- Places section ----------
                    { key: "home",      label: "Home",      icon: Icons.home,      path: "file://" + Quickshell.env("HOME") },
                    { key: "desktop",   label: "Desktop",   icon: Icons.desktop,   path: "file://" + Quickshell.env("HOME") + "/Desktop" },
                    { key: "documents", label: "Documents", icon: Icons.documents, path: "file://" + Quickshell.env("HOME") + "/Documents" },
                    { key: "downloads", label: "Downloads", icon: Icons.downloads, path: "file://" + Quickshell.env("HOME") + "/Downloads" },
                    { key: "music",     label: "Music",     icon: Icons.music,     path: "file://" + Quickshell.env("HOME") + "/Music" },
                    { key: "pictures",  label: "Pictures",  icon: Icons.pictures,  path: "file://" + Quickshell.env("HOME") + "/Pictures" },
                    { key: "videos",    label: "Videos",    icon: Icons.videos,    path: "file://" + Quickshell.env("HOME") + "/Videos" },

                    // ---------- "Places" header (again, per your layout) ----------
                    { key: "---drives---" },

                    // ---------- Custom section ----------
                    { key: "novamk2",    label: "NovaMK2",    icon: Icons.devices,    path: "file://" + Quickshell.env("HOME") + "/NovaMK2" },
                    { key: "steamlinux", label: "SteamLinux", icon: Icons.devices, path: "file://" + Quickshell.env("HOME") + "/SteamLinux" }
                ]
                model: entries

                delegate: Item {
                    width: categories.width
                    height: modelData.key === "---places---" || modelData.key === "---drives---" ? 24 : 30

                    // Header
                    Text {
                        visible: modelData.key === "---places---"
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Places"
                        color: root.textColorSecondary
                        font { family: root.font; pixelSize: root.fontSize - 4; bold: true }
                    }
                    Text {
                        visible: modelData.key === "---drives---"
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Drives"
                        color: root.textColorSecondary
                        font { family: root.font; pixelSize: root.fontSize - 4; bold: true }
                    }

                    // Normal row
                    Rectangle {
                        visible: modelData.key !== "---places---" && modelData.key !== "---drives---"
                        width: parent.width
                        height: 30
                        radius: 8
                        color: {
                            if (categories.selectedCat === modelData.key) root.accentBackground
                            else if (hover.hovered) root.backgroundColor
                            else "transparent"
                        }

                        Row {
                            anchors.left: parent.left
                            anchors.leftMargin: 10
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: 10
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: categories.selectedCat === modelData.key ? root.accentSecondary : Qt.lighter(root.backgroundColor, 4)
                                text: modelData.icon
                                font { family: root.iconFont; pixelSize: root.fontSize + 2 }
                            }
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                color: categories.selectedCat === modelData.key ? root.textColor : Qt.lighter(root.backgroundColor, 4)
                                text: modelData.label
                                font { family: root.font; pixelSize: root.fontSize - 2 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                categories.selectedCat = modelData.key
                                dir.folder = modelData.path
                            }
                        }
                        HoverHandler { id: hover }
                    }
                }
            }
            Rectangle {
                width: 2
                height: 350
                anchors.left: parent.left
                anchors.leftMargin: 210
                color: root.backgroundColor
            }
            ListView {
                anchors.left: parent.left
                anchors.leftMargin: 220
                width: parent.width
                height: 350
                clip: true
                model: dir
                delegate: ItemDelegate {
                    id: del
                    required property string fileName
                    required property bool fileIsDir
                    required property url fileUrl
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 10
                        width: parent.width
                        height: parent.height
                        spacing: 10
                        Item {
                            width: 26
                            height: 26
                            anchors.verticalCenter: parent.verticalCenter

                            Rectangle {
                                width: parent.width
                                height: parent.height
                                color: root.accentBackground
                                radius: 8
                                Text {
                                    anchors.centerIn: parent
                                    color: root.accentSecondary
                                    text: {
                                        if (fileIsDir) {
                                            Icons.folder
                                        } else {
                                            Icons.documents
                                        }
                                    }
                                    font {
                                        family: root.iconFont
                                        pixelSize: root.fontSize - 2
                                    }
                                }
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            color: "white"
                            text: fileName
                            font {
                                family: root.font
                                pixelSize: root.fontSize
                            }
                            //renderType: Text.NativeRendering
                        }
                    }
                    width: ListView.view.width
                    height: ListView.view.height / 10
                    highlighted: filePicker.picked.includes(fileUrl.toString())

                    background: Rectangle {
                        radius: 8
                        color: del.highlighted ? "#33ffffff" : (del.hovered ? "#14ffffff" : "transparent")
                    }

                    onClicked: {
                        if (fileIsDir) { dir.folder = fileUrl; return }
                        if (filePicker.isSave) { nameField.text = fileName; return }
                        const u = fileUrl.toString()
                        if (req.multiple) {
                            filePicker.picked = filePicker.picked.includes(u)
                                ? filePicker.picked.filter(x => x !== u)
                                : filePicker.picked.concat([u])
                        } else {
                            filePicker.accepted([u])   // single-select: click = done
                        }
                    }
                }
            }
        }

        TextField {
            id: nameField
            visible: filePicker.isSave
            Layout.fillWidth: true
            text: req.current_name || ""
            placeholderText: "File name"
            font {
                family: root.font
                pixelSize: root.fontSize
            }
            onTextChanged: filePicker.askOverwrite = false
            onAccepted: filePicker.confirm()
        }

        Text {
            visible: filePicker.askOverwrite
            text: "File exists. Press Enter again to overwrite."
            font {
                family: root.font
                pixelSize: root.fontSize
            }
            color: "#ffb4ab"
        }

        Text {
            visible: req.multiple && filePicker.picked.length > 0
            text: filePicker.picked.length + " selected · Enter to confirm"
            font {
                family: root.font
                pixelSize: root.fontSize
            }
            color: "#aaa"
        }
    }
}
