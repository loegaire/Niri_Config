// BatteryWidget.qml
// Compact battery widget for the vertical bar
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: batteryWidget
    
    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorRed: Theme.critical
    readonly property color colorOrange: Theme.secondaryStrong
    
    property int batteryLevel: 0
    property string batteryState: "unknown"
    property bool isCharging: batteryState === "charging" || batteryState === "full"
    property bool hasBattery: batteryLevel > 0
    
    implicitWidth: 36
    implicitHeight: 36
    color: "transparent"
    
    Process {
        id: batteryProcess
        command: ["cat", "/sys/class/power_supply/BAT0/capacity"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                let val = parseInt(data.trim())
                if (!isNaN(val)) batteryWidget.batteryLevel = val
            }
        }
    }
    
    Process {
        id: stateProcess
        command: ["cat", "/sys/class/power_supply/BAT0/status"]
        running: true
        stdout: SplitParser {
            onRead: data => batteryWidget.batteryState = data.trim().toLowerCase()
        }
    }
    
    Timer {
        interval: 30000
        running: true
        repeat: true
        onTriggered: {
            batteryProcess.running = true
            stateProcess.running = true
        }
    }
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: -2
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (batteryWidget.isCharging) return "\uf0e7"
                if (batteryWidget.batteryLevel > 80) return "\uf240"
                if (batteryWidget.batteryLevel > 60) return "\uf241"
                if (batteryWidget.batteryLevel > 40) return "\uf242"
                if (batteryWidget.batteryLevel > 20) return "\uf243"
                return "\uf244"
            }
            font.family: "Font Awesome 6 Free Solid"
            font.weight: Font.Black
            font.pixelSize: 12
            color: {
                if (batteryWidget.isCharging) return batteryWidget.colorCyan
                if (batteryWidget.batteryLevel <= 20) return batteryWidget.colorRed
                if (batteryWidget.batteryLevel <= 40) return batteryWidget.colorOrange
                return batteryWidget.colorAccent
            }
        }
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: batteryWidget.batteryLevel + "%"
            font.pixelSize: 9
            font.family: "JetBrains Mono"
            color: {
                if (batteryWidget.isCharging) return batteryWidget.colorCyan
                if (batteryWidget.batteryLevel <= 20) return batteryWidget.colorRed
                return batteryWidget.colorAccent
            }
        }
    }
}
