// NetworkWidget.qml
// Compact network status widget for the vertical bar
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: networkWidget
    
    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorRed: Theme.critical
    
    property string connectionName: "Disconnected"
    property string connectionType: "none"
    property int signalStrength: 0
    
    implicitWidth: 36
    implicitHeight: 36
    color: "transparent"
    
    Process {
        id: networkProcess
        command: ["nmcli", "-t", "-f", "NAME,TYPE,DEVICE", "connection", "show", "--active"]
        running: true
        
        stdout: SplitParser {
            onRead: data => {
                let text = data.trim()
                if (!text) return
                let parts = text.split(":")
                let name = parts[0] || ""
                let type = (parts[1] || "").toLowerCase()
                let device = (parts[2] || "").toLowerCase()
                if (device.startsWith("lo") || device.startsWith("docker") || device.startsWith("br-") ||
                    device.startsWith("veth") || device.startsWith("virbr") || type === "bridge" || type === "loopback") {
                    return
                }
                if (type.includes("wireless") || type.includes("wifi") || type === "802-11-wireless") {
                    networkWidget.connectionName = name
                    networkWidget.connectionType = "wifi"
                } else if (type.includes("ethernet") || type === "802-3-ethernet") {
                    if (networkWidget.connectionType !== "wifi") {
                        networkWidget.connectionName = name
                        networkWidget.connectionType = "ethernet"
                    }
                }
            }
        }
        onExited: {
            if (networkWidget.connectionType === "none") {
                networkWidget.connectionName = "Disconnected"
            }
        }
    }
    
    Process {
        id: signalProcess
        command: ["nmcli", "-t", "-f", "IN-USE,SIGNAL", "dev", "wifi", "list", "--rescan", "no"]
        running: networkWidget.connectionType === "wifi"
        
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim()
                if (line.startsWith("*:")) {
                    let val = parseInt(line.split(":")[1])
                    if (!isNaN(val)) networkWidget.signalStrength = val
                }
            }
        }
    }
    
    Timer {
        interval: 10000
        running: true
        repeat: true
        onTriggered: {
            networkWidget.connectionType = "none"
            networkProcess.running = true
        }
    }
    
    onConnectionTypeChanged: {
        if (connectionType === "wifi") signalProcess.running = true
    }
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: -2
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: {
                if (networkWidget.connectionType === "none") return "\uf127"
                if (networkWidget.connectionType === "ethernet") return "\uf6ff"
                if (networkWidget.connectionType === "wifi") return "\uf1eb"
                return "\uf0ac"
            }
            font.family: "Font Awesome 6 Free Solid"
            font.weight: Font.Black
            font.pixelSize: 12
            color: networkWidget.connectionType === "none" ? networkWidget.colorRed : networkWidget.colorCyan
        }
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: networkWidget.connectionType === "none" ? "Off" : (networkWidget.connectionName.length > 4 ? "..." : networkWidget.connectionName)
            font.pixelSize: 9
            font.family: "JetBrains Mono"
            color: networkWidget.connectionType === "none" ? networkWidget.colorRed : networkWidget.colorCyan
        }
    }
    
    ToolTip {
        id: networkToolTip
        text: "Network: " + networkWidget.connectionName
        delay: 500
        visible: netHover.containsMouse
    }
    
    Process {
        id: nmtuiProcess
        command: ["kitty", "--title", "Network Settings", "nmtui"]
    }
    
    MouseArea {
        id: netHover
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: nmtuiProcess.running = true
    }
}
