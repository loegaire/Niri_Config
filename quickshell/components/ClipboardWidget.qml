// ClipboardWidget.qml
// Displays saved clipboard history using cliphist
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: clipboardWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accent
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.border
    readonly property color colorCyan: Theme.accent
    readonly property color colorYellow: Theme.accent
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    // Clipboard history
    property var clipboardItems: []
    property int maxItems: 7
    
    function loadClipboard() {
        clipProcess.running = true
    }
    
    function copyItem(text) {
        copyProcess.command = ["bash", "-c", "echo -n " + JSON.stringify(text) + " | wl-copy"]
        copyProcess.running = true
    }
    
    function clearHistory() {
        clearProcess.running = true
        clipboardItems = []
    }
    
    radius: 8
    clip: true
    color: clipboardWidget.colorMain
    border.width: 1
    border.color: Theme.border
    
    // Process to get clipboard history
    Process {
        id: clipProcess
        command: ["cliphist", "list"]
        
        property string buffer: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => clipProcess.buffer += data
        }
        
        onExited: {
            if (buffer.length > 0) {
                let lines = buffer.trim().split("\n")
                let items = []
                for (let i = 0; i < Math.min(lines.length, clipboardWidget.maxItems); i++) {
                    let line = lines[i]
                    // cliphist format: "id\ttext"
                    let tabIndex = line.indexOf("\t")
                    if (tabIndex > 0) {
                        let item = {
                            id: line.substring(0, tabIndex),
                            text: line.substring(tabIndex + 1).trim()
                        }
                        items.push(item)
                    }
                }
                clipboardWidget.clipboardItems = items
            }
            buffer = ""
        }
    }
    
    Process {
        id: copyProcess
        command: ["true"]
    }
    
    Process {
        id: clearProcess
        command: ["cliphist", "wipe"]
        onExited: clipboardWidget.loadClipboard()
    }
    
    // Refresh every 5 seconds
    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: clipboardWidget.loadClipboard()
    }
    
    Component.onCompleted: loadClipboard()
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 6
        
        // Compact Header
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5
            color: clipboardWidget.colorAccent
            
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                spacing: 4
            
                Text {
                    text: "\uf328"  // fa-clipboard
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 15
                    color: Theme.onAccentText
                }
            
                Text {
                    text: "Clipboard"
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.onAccentText
                }
            
                Item { Layout.fillWidth: true }
            
                // Clear button
                Rectangle {
                    width: 20
                    height: 20
                    radius: 4
                    color: clearBtn.containsMouse ? clipboardWidget.colorSecondary : Theme.onAccentText
                    visible: clipboardWidget.clipboardItems.length > 0
                
                    Text {
                        anchors.centerIn: parent
                        text: "\uf1f8"  // fa-trash
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 13
                        color: clipboardWidget.colorAccent
                    }
                
                    MouseArea {
                        id: clearBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clipboardWidget.clearHistory()
                    }
                }
            }
        }
        
        // Clipboard items list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 2
            
            model: clipboardWidget.clipboardItems
            
            // Empty state
            Text {
                anchors.centerIn: parent
                text: "No clipboard history"
                font.pixelSize: 12
                font.family: "JetBrains Mono"
                color: clipboardWidget.colorSecondary2
                opacity: 0.5
                visible: clipboardWidget.clipboardItems.length === 0
            }
            
            delegate: Rectangle {
                id: clipItem
                required property var modelData
                required property int index
                
                width: ListView.view.width
                height: 34
                radius: 4
                color: itemHover.containsMouse ? Theme.surface2 : Theme.surface
                border.width: 1
                border.color: itemHover.containsMouse ? clipboardWidget.colorSecondary : Theme.border
                
                RowLayout {
                    anchors {
                        fill: parent
                        leftMargin: 10
                        rightMargin: 10
                    }
                    spacing: 8
                    
                    // Index badge
                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: clipboardWidget.colorAccentDim
                        
                        Text {
                            anchors.centerIn: parent
                            text: (clipItem.index + 1).toString()
                            font.pixelSize: 11
                            font.family: "JetBrains Mono"
                            font.bold: true
                            color: clipboardWidget.colorMain
                        }
                    }
                    
                    // Clipboard text (truncated)
                    Text {
                        Layout.fillWidth: true
                        text: clipItem.modelData.text.substring(0, 40) + (clipItem.modelData.text.length > 40 ? "..." : "")
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        elide: Text.ElideRight
                    }
                    
                    // Copy button (visible on hover)
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 4
                        color: copyBtn.containsMouse ? clipboardWidget.colorAccent : "transparent"
                        visible: itemHover.containsMouse
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uf0c5"  // fa-copy
                            font.family: "Font Awesome 6 Free Solid"
                            font.weight: Font.Black
                            font.pixelSize: 11
                            color: copyBtn.containsMouse ? clipboardWidget.colorMain : clipboardWidget.colorAccent
                        }
                        
                        MouseArea {
                            id: copyBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clipboardWidget.copyItem(clipItem.modelData.text)
                        }
                    }
                }
                
                MouseArea {
                    id: itemHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.LeftButton
                    cursorShape: Qt.PointingHandCursor
                    onClicked: clipboardWidget.copyItem(clipItem.modelData.text)
                }
            }
        }
    }
}
