// ToggleButtonsWidget.qml
// Toggle switches (pill style) and action buttons
// Theme: DARK with light accent header strip
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: togglesWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.border
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorYellow: Theme.accentStrong
    readonly property color colorRed: Theme.critical
    readonly property color colorOrange: Theme.secondaryStrong
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    // Toggle states (8 toggles now)
    property var toggleStates: [false, true, false, true, false, false, true, false]
    
    function toggleState(index) {
        let newStates = toggleStates.slice()
        newStates[index] = !newStates[index]
        toggleStates = newStates
    }
    
    // Process launchers
    Process {
        id: bluetoothProcess
        command: ["blueman-manager"]
    }
    
    Process {
        id: firefoxProcess
        command: ["firefox"]
    }
    
    Process {
        id: terminalProcess
        command: ["kitty"]
    }
    
    Process {
        id: fileManagerProcess
        command: ["thunar"]
    }
    
    Process {
        id: screenshotProcess
        command: ["grimblast", "copy", "area"]
    }
    
    Process {
        id: screenRecordProcess
        command: ["obs"]
    }
    
    Process {
        id: settingsProcess
        command: ["gnome-control-center"]
    }
    
    // Action button handler
    function handleAction(label) {
        switch(label) {
            case "BT":
                bluetoothProcess.running = true
                break
            case "Web":
                firefoxProcess.running = true
                break
            case "Term":
                terminalProcess.running = true
                break
            case "Files":
                fileManagerProcess.running = true
                break
            case "Snap":
                screenshotProcess.running = true
                break
            case "Rec":
                screenRecordProcess.running = true
                break
            case "Cfg":
                settingsProcess.running = true
                break
            default:
                console.log("Action:", label)
        }
    }
    
    radius: 4
    property int toggleColumns: width < 150 ? 3 : 4
    property int actionColumns: width < 150 ? 4 : 5
    clip: true
    
    // DARK theme - solid main dark blue
    color: togglesWidget.colorMain
    
    border.width: 1
    border.color: colorAccent
    
    // Compact header strip
    Rectangle {
        id: toggleHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 22
        radius: 4
        color: togglesWidget.colorAccent
        
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
                text: "\uf013"  // fa-gear
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 10
                color: togglesWidget.colorMain
            }
            
            Text {
                text: "Toggles"
                font.pixelSize: 13
                font.family: "JetBrains Mono"
                font.bold: true
                color: togglesWidget.colorMain
            }
        }
    }
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 4
            topMargin: 26
        }
        spacing: 4
        
        // Pill-style toggle switches grid
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 80
            Layout.preferredHeight: 80

            GridLayout {
                id: toggleGrid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: togglesWidget.toggleColumns
                rowSpacing: 2
                columnSpacing: 2
                
                Repeater {
                    model: [
                        { icon: "\uf017", label: "DND", color: togglesWidget.colorSecondary },
                        { icon: "\uf186", label: "Night", color: togglesWidget.colorCyan },
                        { icon: "\uf0c2", label: "Sync", color: togglesWidget.colorSecondary2 },
                        { icon: "\uf023", label: "Lock", color: togglesWidget.colorYellow },
                        { icon: "\uf1eb", label: "WiFi", color: togglesWidget.colorOrange },
                        { icon: "\uf293", label: "BT", color: togglesWidget.colorCyan },
                        { icon: "\uf3c5", label: "GPS", color: togglesWidget.colorRed },
                        { icon: "\uf2dc", label: "Cool", color: togglesWidget.colorSecondary2 }
                    ]
                    
                    // Toggle switch item with pill and label
                    Item {
                        id: toggleItem
                        required property var modelData
                        required property int index
                        
                        property bool isActive: togglesWidget.toggleStates[index] || false
                        
                        Layout.minimumHeight: 38
                        Layout.preferredHeight: 38
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 2
                            
                            // Pill-shaped toggle switch
                            Rectangle {
                                id: pillTrack
                                Layout.alignment: Qt.AlignHCenter
                                width: 34
                                height: 20
                                radius: 4
                                color: toggleItem.isActive ? toggleItem.modelData.color : togglesWidget.colorMainLight
                                border.width: 1
                                border.color: toggleItem.isActive ? Qt.darker(toggleItem.modelData.color, 1.2) : togglesWidget.colorAccentDim
                                
                                Behavior on color { ColorAnimation { duration: 200 } }
                                
                                // Sliding circular knob
                                Rectangle {
                                    id: knob
                                    width: 14
                                    height: 16
                                    radius: 3
                                    y: 2
                                    x: toggleItem.isActive ? parent.width - width - 2 : 2
                                    
                                    color: toggleItem.isActive ? togglesWidget.colorMain : togglesWidget.colorAccent
                                    border.width: 1
                                    border.color: toggleItem.isActive ? Qt.darker(toggleItem.modelData.color, 1.3) : togglesWidget.colorAccentDim
                                    
                                    Behavior on x { NumberAnimation { duration: 200; easing.type: Easing.OutCubic } }
                                    Behavior on color { ColorAnimation { duration: 200 } }
                                    
                                    // Icon inside knob
                                     Text {
                                         anchors.centerIn: parent
                                         text: toggleItem.modelData.icon
                                         font.family: "Font Awesome 6 Free Solid"
                                         font.weight: Font.Black
                                         font.pixelSize: 11
                                         color: toggleItem.isActive ? togglesWidget.colorMain : toggleItem.modelData.color
                                     }
                                }
                                
                                // Hover effect
                                scale: toggleHover.containsMouse ? 1.1 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                
                                MouseArea {
                                    id: toggleHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        // Special handling for Bluetooth toggle
                                        if (toggleItem.modelData.label === "BT") {
                                            togglesWidget.bluetoothProcess.running = true
                                        }
                                        togglesWidget.toggleState(toggleItem.index)
                                    }
                                }
                            }
                            
                            // Label under the toggle
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: toggleItem.modelData.label
                                font.pixelSize: 9
                                font.family: "JetBrains Mono"
                                font.bold: true
                                color: toggleItem.isActive ? togglesWidget.colorAccent : togglesWidget.colorAccentDim
                            }
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
            color: togglesWidget.colorAccent
            opacity: 0.3
        }
        
        // Small circular action buttons - 2 rows
        Item {
            Layout.fillWidth: true
            Layout.minimumHeight: 70
            Layout.preferredHeight: 70

            GridLayout {
                id: actionGrid
                anchors.horizontalCenter: parent.horizontalCenter
                columns: togglesWidget.actionColumns
                rowSpacing: 2
                columnSpacing: 2
                
                Repeater {
                    model: [
                        { icon: "\uf2f9", label: "Snap", color: togglesWidget.colorCyan },
                        { icon: "\uf03d", label: "Rec", color: togglesWidget.colorRed },
                        { icon: "\uf1de", label: "Cfg", color: togglesWidget.colorSecondary },
                        { icon: "\uf07b", label: "Files", color: togglesWidget.colorOrange },
                        { icon: "\uf120", label: "Term", color: togglesWidget.colorAccentDim },
                        { icon: "\uf1fc", label: "Paint", color: togglesWidget.colorSecondary2 },
                        { icon: "\uf001", label: "Music", color: togglesWidget.colorYellow },
                        { icon: "\uf269", label: "Web", color: togglesWidget.colorCyan },
                        { icon: "\uf11b", label: "Game", color: togglesWidget.colorRed },
                        { icon: "\uf059", label: "Help", color: togglesWidget.colorAccentDim }
                    ]
                    
                    // Small circular button
                    Item {
                        id: btnItem
                        required property var modelData
                        required property int index
                        
                        Layout.minimumHeight: 34
                        Layout.preferredHeight: 34
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 1
                            
                            // Circular button
                            Rectangle {
                                id: actionBtn
                                Layout.alignment: Qt.AlignHCenter
                                width: 24
                                height: 24
                                radius: 12
                                
                                color: actionHover.containsMouse ? btnItem.modelData.color : togglesWidget.colorMainLight
                                border.width: 1
                                border.color: actionHover.containsMouse ? Qt.darker(btnItem.modelData.color, 1.2) : togglesWidget.colorAccentDim
                                
                                scale: actionHover.containsMouse ? 1.15 : 1.0
                                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                                Behavior on color { ColorAnimation { duration: 150 } }
                                
                                // Icon
                                Text {
                                    anchors.centerIn: parent
                                    text: btnItem.modelData.icon
                                    font.family: "Font Awesome 6 Free Solid"
                                    font.weight: Font.Black
                                    font.pixelSize: 11
                                    color: actionHover.containsMouse ? togglesWidget.colorMain : togglesWidget.colorAccent
                                }
                                
                                MouseArea {
                                    id: actionHover
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: togglesWidget.handleAction(btnItem.modelData.label)
                                }
                            }
                            
                            // Label under button
                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                text: btnItem.modelData.label
                                font.pixelSize: 7
                                font.family: "JetBrains Mono"
                                color: togglesWidget.colorAccentDim
                            }
                        }
                    }
                }
            }
        }
    }
}
