// PowerWidget.qml
// Power menu with shutdown, reboot, and logout buttons
// Theme: DARK with light accent header strip
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: powerWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.secondary2
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorYellow: Theme.secondaryStrong
    readonly property color colorRed: Theme.critical
    readonly property color colorOrange: Theme.secondaryStrong
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    radius: 10
    clip: true
    
    // DARK theme - solid main surface
    color: powerWidget.colorMain
    
    Image {
        anchors.fill: parent
        source: "file:///home/thinh/niri-config/quickshell/asset2.jpg"
        fillMode: Image.PreserveAspectCrop
        opacity: 0.45
        sourceSize.width: width
        sourceSize.height: height
        z: -1
    }
    
    border.width: 1
    border.color: colorAccent
    
    // Power commands
    Process {
        id: powerProcess
        command: ["true"]
    }
    
    function shutdown() {
        powerProcess.command = ["systemctl", "poweroff"]
        powerProcess.running = true
    }
    
    function reboot() {
        powerProcess.command = ["systemctl", "reboot"]
        powerProcess.running = true
    }
    
    function logout() {
        powerProcess.command = ["niri", "msg", "action", "quit"]
        powerProcess.running = true
    }
    
    function suspend() {
        powerProcess.command = ["systemctl", "suspend"]
        powerProcess.running = true
    }
    
    // Compact header strip
    Rectangle {
        id: powerHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 22
        radius: 4
        color: powerWidget.colorAccent
        
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
                text: "\uf011"  // fa-power-off
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 10
                color: powerWidget.colorMain
            }
            
            Text {
                text: "Power"
                font.pixelSize: 13
                font.family: "JetBrains Mono"
                font.bold: true
                color: powerWidget.colorMain
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
        
        // Power buttons in 2x2 grid for compact layout
        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            rowSpacing: 4
            columnSpacing: 4
            
            // Logout button
            Rectangle {
                id: logoutRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 35
                
                radius: 4
                color: logoutBtn.containsMouse ? powerWidget.colorAccent : powerWidget.colorMainLight
                border.width: 2
                border.color: logoutBtn.containsMouse ? Qt.darker(powerWidget.colorAccent, 1.2) : powerWidget.colorAccentDim
                
                scale: logoutBtn.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf2f5"  // fa-right-from-bracket
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 14
                        color: logoutBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorAccent
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Out"
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: logoutBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorAccent
                    }
                }
                
                MouseArea {
                    id: logoutBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerWidget.logout()
                }
            }
            
            // Suspend button
            Rectangle {
                id: suspendRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 35
                
                radius: 4
                color: suspendBtn.containsMouse ? powerWidget.colorCyan : powerWidget.colorMainLight
                border.width: 2
                border.color: suspendBtn.containsMouse ? Qt.darker(powerWidget.colorCyan, 1.2) : powerWidget.colorAccentDim
                
                scale: suspendBtn.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf186"  // fa-moon
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 14
                        color: suspendBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorCyan
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Sleep"
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: suspendBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorCyan
                    }
                }
                
                MouseArea {
                    id: suspendBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerWidget.suspend()
                }
            }
            
            // Reboot button
            Rectangle {
                id: rebootRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 35
                
                radius: 4
                color: rebootBtn.containsMouse ? powerWidget.colorOrange : powerWidget.colorMainLight
                border.width: 2
                border.color: rebootBtn.containsMouse ? Qt.darker(powerWidget.colorOrange, 1.2) : powerWidget.colorAccentDim
                
                scale: rebootBtn.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf2f1"  // fa-rotate
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 14
                        color: rebootBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorOrange
                        
                        rotation: rebootBtn.containsMouse ? 360 : 0
                        Behavior on rotation { NumberAnimation { duration: 500; easing.type: Easing.InOutQuad } }
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Boot"
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: rebootBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorOrange
                    }
                }
                
                MouseArea {
                    id: rebootBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerWidget.reboot()
                }
            }
            
            // Shutdown button
            Rectangle {
                id: shutdownRect
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 35
                
                radius: 4
                color: shutdownBtn.containsMouse ? powerWidget.colorRed : powerWidget.colorMainLight
                border.width: 2
                border.color: shutdownBtn.containsMouse ? Qt.darker(powerWidget.colorRed, 1.2) : powerWidget.colorAccentDim
                
                scale: shutdownBtn.containsMouse ? 1.05 : 1.0
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
                Behavior on color { ColorAnimation { duration: 200 } }
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 2
                    
                    Text {
                        id: shutdownIcon
                        Layout.alignment: Qt.AlignHCenter
                        text: "\uf011"  // fa-power-off
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 14
                        color: shutdownBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorRed
                    }
                    
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "Off"
                        font.pixelSize: 8
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: shutdownBtn.containsMouse ? powerWidget.colorMain : powerWidget.colorRed
                    }
                }
                
                MouseArea {
                    id: shutdownBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: powerWidget.shutdown()
                }
            }
        }
    }
}
