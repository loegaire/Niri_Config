// NotesWidget.qml
// Quick note-taking widget with cute Japanese emoticon prompt
// Theme: DARK with light accent header strip
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: notesWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.border
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.muted2
    readonly property color colorCyan: Theme.muted
    readonly property color colorYellow: Theme.secondaryStrong
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    // Notes storage
    property var notes: []
    property string notesFile: "/tmp/quickshell-notes.txt"
    
    property string currentPrompt: "+"
    
    function addNote(text: string) {
        if (text.trim().length === 0) return
        let newNotes = notes.slice()
        newNotes.unshift({
            text: text.trim(),
            time: new Date().toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})
        })
        // Keep max 50 notes
        if (newNotes.length > 50) {
            newNotes = newNotes.slice(0, 50)
        }
        notes = newNotes
        saveNotes()
    }
    
    function removeNote(index: int) {
        let newNotes = notes.slice()
        newNotes.splice(index, 1)
        notes = newNotes
        saveNotes()
    }
    
    function clearNotes() {
        notes = []
        saveNotes()
    }
    
    function saveNotes() {
        let content = notes.map(n => n.time + " | " + n.text).join("\n")
        saveProcess.command = ["bash", "-c", "echo " + JSON.stringify(content) + " > " + notesFile]
        saveProcess.running = true
    }
    
    function loadNotes() {
        loadProcess.running = true
    }
    
    radius: 8
    
    clip: true
    color: notesWidget.colorMain
    border.width: 1
    border.color: Theme.border
    
    Process {
        id: saveProcess
        command: ["true"]
    }
    
    Process {
        id: loadProcess
        command: ["cat", notesWidget.notesFile]
        
        property string buffer: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => loadProcess.buffer += data
        }
        
        onExited: {
            if (buffer.length > 0) {
                let lines = buffer.trim().split("\n")
                let loadedNotes = []
                for (let line of lines) {
                    let parts = line.split(" | ")
                    if (parts.length >= 2) {
                        loadedNotes.push({
                            time: parts[0],
                            text: parts.slice(1).join(" | ")
                        })
                    }
                }
                notesWidget.notes = loadedNotes
            }
            buffer = ""
        }
    }
    
    Component.onCompleted: loadNotes()
    
    // Compact header strip
    Rectangle {
        id: notesHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 30
        radius: 4
        color: notesWidget.colorAccent
        
        Rectangle {
            anchors.bottom: parent.bottom
            anchors.left: parent.left
            anchors.right: parent.right
            height: 8
            color: parent.color
        }
        
        RowLayout {
            anchors {
                fill: parent
                leftMargin: 8
                rightMargin: 8
            }
            spacing: 4
            
            Text {
                text: "\uf249"  // fa-pen-to-square
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 13
                color: Theme.onAccentText
            }
            
            Text {
                text: "Notes"
                font.pixelSize: 16
                font.family: "JetBrains Mono"
                font.bold: true
                color: Theme.onAccentText
            }
            
            Item { Layout.fillWidth: true }
            
            // Note count
            Text {
                text: notesWidget.notes.length + ""
                font.pixelSize: 12
                font.family: "JetBrains Mono"
                color: Theme.onAccentText
                opacity: 0.9
            }
            
            // Clear button
            Rectangle {
                width: 22
                height: 22
                radius: 11
                color: clearBtn.containsMouse ? notesWidget.colorMain : Theme.text
                visible: notesWidget.notes.length > 0
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf1f8"  // fa-trash
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 12
                    color: Theme.onAccentText
                }
                
                MouseArea {
                    id: clearBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: notesWidget.clearNotes()
                }
            }
        }
    }
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
            topMargin: 40
        }
        spacing: 6
        
        // Input area with cute prompt
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 36
            radius: 4
            color: Theme.surface
            border.width: 1
            border.color: noteInput.activeFocus ? Theme.accent : notesWidget.colorAccentDim
            
            MouseArea {
                anchors.fill: parent
                onClicked: noteInput.forceActiveFocus()
            }
            
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                spacing: 6
                
                Text {
                    text: notesWidget.currentPrompt
                    font.pixelSize: 17
                    font.bold: true
                    color: Theme.muted
                }
                
                TextInput {
                    id: noteInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    verticalAlignment: TextInput.AlignVCenter
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    color: Theme.text
                    clip: true
                    activeFocusOnPress: true
                    selectByMouse: true
                    selectionColor: notesWidget.colorAccentDim
                    selectedTextColor: notesWidget.colorMain
                    
                    property string placeholderText: "Write something..."
                    
                    Text {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        text: noteInput.placeholderText
                        font: noteInput.font
                        color: Theme.muted
                        opacity: 0.5
                        visible: !noteInput.text && !noteInput.activeFocus
                    }
                    
                    onAccepted: {
                        notesWidget.addNote(text)
                        text = ""
                    }
                    
                    Keys.onEscapePressed: {
                        text = ""
                        focus = false
                    }
                }
                
                // Submit button
                Rectangle {
                    width: 24
                    height: 24
                    radius: 12
                    color: submitBtn.containsMouse ? notesWidget.colorMainLight : "transparent"
                    
                    Text {
                        anchors.centerIn: parent
                        text: "\uf054"  // fa-chevron-right
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 11
                        color: Theme.muted
                    }
                    
                    MouseArea {
                        id: submitBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            notesWidget.addNote(noteInput.text)
                            noteInput.text = ""
                        }
                    }
                }
            }
        }
        
        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            radius: 1
            color: Theme.border
            opacity: 0.3
        }
        
        // Notes list
        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 4
            
            model: notesWidget.notes
            
            // Empty state overlay
            Text {
                anchors.centerIn: parent
                text: "No notes yet"
                font.pixelSize: 14
                font.family: "JetBrains Mono"
                color: Theme.muted
                opacity: 0.6
                visible: notesWidget.notes.length === 0
            }
            
            delegate: Rectangle {
                id: noteItem
                required property var modelData
                required property int index
                
                width: ListView.view.width
                height: Math.min(76, noteContent.implicitHeight + 16)
                
                radius: 6
                color: noteHover.containsMouse ? Theme.surface2 : Theme.surface
                border.width: 1
                border.color: noteHover.containsMouse ? Theme.muted2 : Theme.border
                
                RowLayout {
                    id: noteContent
                    anchors {
                        fill: parent
                        margins: 8
                    }
                    spacing: 10
                    
                    // Time
                    Text {
                        text: noteItem.modelData.time
                        font.pixelSize: 11
                        font.family: "JetBrains Mono"
                        color: notesWidget.colorSecondary2
                        Layout.alignment: Qt.AlignTop
                    }
                    
                    // Note text
                    Text {
                        Layout.fillWidth: true
                        text: noteItem.modelData.text
                        font.pixelSize: 12
                        font.family: "JetBrains Mono"
                        color: Theme.text
                        wrapMode: Text.WordWrap
                        maximumLineCount: 2
                        elide: Text.ElideRight
                    }
                    
                    // Delete button
                    Rectangle {
                        width: 22
                        height: 22
                        radius: 4
                        color: deleteBtn.containsMouse ? Theme.border : "transparent"
                        Layout.alignment: Qt.AlignTop
                        visible: noteHover.containsMouse
                        
                        Text {
                            anchors.centerIn: parent
                            text: "\uf00d"  // fa-xmark
                            font.family: "Font Awesome 6 Free Solid"
                            font.pixelSize: 11
                            color: Theme.muted
                        }
                        
                        MouseArea {
                            id: deleteBtn
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: notesWidget.removeNote(noteItem.index)
                        }
                    }
                }
                
                MouseArea {
                    id: noteHover
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }
    }
}
