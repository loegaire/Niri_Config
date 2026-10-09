// SystemInfoWidget.qml
// Displays system information with markdown-like formatting
// Theme: DARK with subtle light divider accents (alternating pattern)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: sysInfo

    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accent
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondaryStrong
    readonly property color colorSecondary2: Theme.border
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorYellow: Theme.accentStrong
    readonly property color colorRed: Theme.critical
    readonly property color colorOrange: Theme.secondaryStrong
    readonly property color colorBlue: Theme.text
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }

    // System info properties
    property string uptime: "..."
    property string processCount: "..."
    property string ramUsage: "..."
    property string ramPercent: "0"
    property string storageUsage: "..."
    property string storagePercent: "0"
    property string cpuUsage: "0"
    property string kernelVersion: "..."
    property string uploadSpeed: "0 B/s"
    property string downloadSpeed: "0 B/s"

    // For network speed calculation
    property real lastRxBytes: 0
    property real lastTxBytes: 0

    radius: 8
    clip: true
    color: sysInfo.colorMain

    border.width: 1
    border.color: Theme.border

    // Fast update timer (1 second) - CPU, RAM, Network
    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: {
            cpuProcess.running = true
            ramProcess.running = true
            networkProcess.running = true
            processProcess.running = true
        }
    }

    // Slow update timer (1 hour) - Kernel, Storage, Uptime
    Timer {
        interval: 3600000
        running: true
        repeat: true
        onTriggered: {
            kernelProcess.running = true
            storageProcess.running = true
        }
    }

    // Uptime updates every minute
    Timer {
        interval: 60000
        running: true
        repeat: true
        onTriggered: uptimeProcess.running = true
    }

    // Initial load
    Component.onCompleted: {
        uptimeProcess.running = true
        kernelProcess.running = true
        storageProcess.running = true
        cpuProcess.running = true
        ramProcess.running = true
        networkProcess.running = true
        processProcess.running = true
    }

    // Process definitions
    Process {
        id: uptimeProcess
        command: ["uptime", "-p"]
        stdout: SplitParser {
            onRead: data => {
                sysInfo.uptime = data.trim().replace("up ", "")
            }
        }
    }

    Process {
        id: processProcess
        command: ["bash", "-c", "ps aux | wc -l"]
        stdout: SplitParser {
            onRead: data => {
                let count = parseInt(data.trim()) - 1
                sysInfo.processCount = count.toString()
            }
        }
    }

    Process {
        id: ramProcess
        command: ["bash", "-c", "free -h | awk '/^Mem:/ {print $3\"/\"$2}' && free | awk '/^Mem:/ {printf \"%.0f\", $3/$2*100}'"]
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim()
                if (line.includes("/")) {
                    sysInfo.ramUsage = line
                } else if (line.match(/^\d+$/)) {
                    sysInfo.ramPercent = line
                }
            }
        }
    }

    Process {
        id: storageProcess
        command: ["bash", "-c", "df -h / | awk 'NR==2 {print $3\"/\"$2}' && df / | awk 'NR==2 {print $5}' | tr -d '%'"]
        stdout: SplitParser {
            onRead: data => {
                let line = data.trim()
                if (line.includes("/")) {
                    sysInfo.storageUsage = line
                } else if (line.match(/^\d+$/)) {
                    sysInfo.storagePercent = line
                }
            }
        }
    }

    Process {
        id: cpuProcess
        command: ["bash", "-c", "top -bn1 | grep 'Cpu(s)' | awk '{print 100 - $8}' | cut -d'.' -f1"]
        stdout: SplitParser {
            onRead: data => {
                let val = data.trim()
                if (val.match(/^\d+$/)) {
                    sysInfo.cpuUsage = val
                }
            }
        }
    }

    Process {
        id: kernelProcess
        command: ["uname", "-r"]
        stdout: SplitParser {
            onRead: data => {
                sysInfo.kernelVersion = data.trim()
            }
        }
    }

    Process {
        id: networkProcess
        command: ["bash", "-c", "cat /proc/net/dev | awk '/wl|eth|enp/ {rx+=$2; tx+=$10} END {print rx, tx}'"]
        stdout: SplitParser {
            onRead: data => {
                let parts = data.trim().split(" ")
                if (parts.length >= 2) {
                    let rxBytes = parseFloat(parts[0]) || 0
                    let txBytes = parseFloat(parts[1]) || 0

                    if (sysInfo.lastRxBytes > 0) {
                        let rxDiff = rxBytes - sysInfo.lastRxBytes
                        let txDiff = txBytes - sysInfo.lastTxBytes
                        sysInfo.downloadSpeed = formatBytes(rxDiff) + "/s"
                        sysInfo.uploadSpeed = formatBytes(txDiff) + "/s"
                    }

                    sysInfo.lastRxBytes = rxBytes
                    sysInfo.lastTxBytes = txBytes
                }
            }
        }
    }

    function formatBytes(bytes: real): string {
        if (bytes < 1024) return bytes.toFixed(0) + " B"
        if (bytes < 1024 * 1024) return (bytes / 1024).toFixed(1) + " KB"
        if (bytes < 1024 * 1024 * 1024) return (bytes / 1024 / 1024).toFixed(1) + " MB"
        return (bytes / 1024 / 1024 / 1024).toFixed(2) + " GB"
    }

    ColumnLayout {
        id: infoColumn
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 6

        // Compact header with light accent bar
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 5
            color: sysInfo.colorAccent

            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                spacing: 4

                Text {
                    text: "\uf2db"
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 13
                    color: Theme.onAccentText
                }

                Text {
                    text: "System"
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.onAccentText
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            radius: 1
            color: sysInfo.colorAccent
            opacity: 0.3
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            columns: 2
            columnSpacing: 18
            rowSpacing: 12

            InfoRow {
                icon: "\uf017"
                label: "Up"
                value: sysInfo.uptime
                valueColor: Theme.accentStrong
            }

            InfoRow {
                icon: "\uf0ae"
                label: "Procs"
                value: sysInfo.processCount
                valueColor: sysInfo.colorSecondary
            }

            InfoRowWithBar {
                icon: "\uf538"
                label: "RAM"
                value: sysInfo.ramUsage
                percent: parseInt(sysInfo.ramPercent) || 0
                barColor: sysInfo.colorCyan
            }

            InfoRowWithBar {
                icon: "\uf2db"
                label: "CPU"
                value: sysInfo.cpuUsage + "%"
                percent: parseInt(sysInfo.cpuUsage) || 0
                barColor: sysInfo.colorOrange
            }

            InfoRowWithBar {
                icon: "\uf0a0"
                label: "Disk"
                value: sysInfo.storageUsage
                percent: parseInt(sysInfo.storagePercent) || 0
                barColor: sysInfo.colorYellow
            }

            InfoRow {
                icon: "\uf17c"
                label: "Kern"
                value: sysInfo.kernelVersion
                valueColor: sysInfo.colorSecondary2
            }

            InfoRow {
                icon: "\uf019"
                label: "\u2193"
                value: sysInfo.downloadSpeed
                valueColor: Theme.accentStrong
            }

            InfoRow {
                icon: "\uf093"
                label: "\u2191"
                value: sysInfo.uploadSpeed
                valueColor: sysInfo.colorSecondary
            }
        }
    }

    component InfoRow: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""
        property color valueColor: sysInfo.colorAccent

        Layout.fillWidth: true
        Layout.preferredHeight: 24
        spacing: 7

        Text {
            text: icon
            font.family: "Font Awesome 6 Free Solid"
            font.pixelSize: 12
            color: valueColor
            Layout.preferredWidth: 18
        }

        Text {
            text: label
            font.pixelSize: 12
            font.family: "JetBrains Mono"
            color: Theme.text
            Layout.preferredWidth: 52
        }

        Text {
            Layout.fillWidth: true
            text: value
            font.pixelSize: 13
            font.family: "JetBrains Mono"
            font.bold: true
            color: valueColor
            horizontalAlignment: Text.AlignRight
            elide: Text.ElideRight
        }
    }

    component InfoRowWithBar: ColumnLayout {
        property string icon: ""
        property string label: ""
        property string value: ""
        property int percent: 0
        property color barColor: sysInfo.colorCyan

        Layout.fillWidth: true
        Layout.preferredHeight: 48
        spacing: 7

        RowLayout {
            Layout.fillWidth: true
            spacing: 7

            Text {
                text: icon
                font.family: "Font Awesome 6 Free Solid"
                font.pixelSize: 12
                color: sysInfo.colorSecondary2
                Layout.preferredWidth: 18
            }

            Text {
                text: label
                font.pixelSize: 12
                font.family: "JetBrains Mono"
                color: Theme.text
            }

            Item { Layout.fillWidth: true }

            Text {
                text: value
                font.pixelSize: 13
                font.family: "JetBrains Mono"
                font.bold: true
                color: barColor
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 3
            radius: 2
            color: sysInfo.colorMain

            Rectangle {
                width: (percent / 100) * parent.width
                height: parent.height
                radius: parent.radius
                color: barColor

                Behavior on width {
                    NumberAnimation { duration: 200 }
                }
            }
        }
    }
}
