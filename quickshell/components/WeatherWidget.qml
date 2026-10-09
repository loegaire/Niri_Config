// WeatherWidget.qml
// Displays weather information with minimalistic design
// Theme: DARK with subtle light accent header (alternating pattern)
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: weatherWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.border
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.muted2
    readonly property color colorCyan: Theme.muted
    readonly property color colorYellow: Theme.secondaryStrong
    readonly property color colorOrange: Theme.secondary2
    readonly property color colorBlue: Theme.muted
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    // Weather data
    property string location: "..."
    property string temperature: "--"
    property string condition: "unknown"
    property string humidity: "--"
    property string windSpeed: "--"
    property string feelsLike: "--"
    
    // Weather icon mapping - using confirmed working Font Awesome 6 Free icons
    function getWeatherIcon(cond: string): string {
        let c = cond.toLowerCase()
        if (c.includes("clear") || c.includes("sunny")) return "\uf185"  // fa-sun
        if (c.includes("partly")) return "\uf0c2"  // fa-cloud
        if (c.includes("rain") || c.includes("drizzle") || c.includes("shower")) return "\uf043"  // fa-droplet
        if (c.includes("thunder") || c.includes("storm")) return "\uf0e7"  // fa-bolt
        if (c.includes("snow") || c.includes("sleet")) return "\uf2dc"  // fa-snowflake
        if (c.includes("mist") || c.includes("fog") || c.includes("haze")) return "\uf0c2"  // fa-cloud for mist
        if (c.includes("wind")) return "\uf0c2"  // fa-cloud for wind
        if (c.includes("cloud") || c.includes("overcast")) return "\uf0c2"  // fa-cloud
        return "\uf0c2"  // default: cloud
    }
    
    function getWeatherColor(cond: string): color {
        let c = cond.toLowerCase()
        if (c.includes("clear") || c.includes("sunny")) return colorYellow
        if (c.includes("rain") || c.includes("drizzle")) return colorBlue
        if (c.includes("thunder") || c.includes("storm")) return colorSecondary2
        if (c.includes("snow")) return Theme.text
        if (c.includes("mist") || c.includes("fog")) return colorSecondary2
        if (c.includes("cloud")) return colorBlue
        return colorBlue
    }
    
    radius: 8
    clip: true
    color: weatherWidget.colorMain
    border.width: 1
    border.color: Theme.border
    
    // Large weather icon - displayed separately for visibility
    property string weatherIcon: getWeatherIcon(condition)
    property color weatherIconColor: getWeatherColor(condition)
    
    // Fetch weather using wttr.in (free, no API key needed)
    Process {
        id: weatherProcess
        command: ["curl", "-s", "wttr.in/?format=%l|%t|%C|%h|%w|%f"]
        running: false
        
        property string outputBuffer: ""
        
        stdout: SplitParser {
            splitMarker: ""
            onRead: data => {
                weatherProcess.outputBuffer += data
            }
        }
        
        onExited: {
            let parts = outputBuffer.split("|")
            if (parts.length >= 6) {
                weatherWidget.location = parts[0].trim()
                weatherWidget.temperature = parts[1].trim().replace("+", "")
                weatherWidget.condition = parts[2].trim()
                weatherWidget.humidity = parts[3].trim()
                weatherWidget.windSpeed = parts[4].trim()
                weatherWidget.feelsLike = parts[5].trim().replace("+", "")
            }
            outputBuffer = ""
        }
    }
    
    // Refresh every 10 minutes
    Timer {
        interval: 600000
        running: true
        repeat: true
        onTriggered: {
            if (!weatherProcess.running) {
                weatherProcess.running = true
            }
        }
    }
    
    // Initial load
    Component.onCompleted: weatherProcess.running = true
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
        }
        spacing: 6
        
        // Compact header with light accent strip
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 30
            radius: 4
            color: weatherWidget.colorAccent
            
            RowLayout {
                anchors {
                    fill: parent
                    leftMargin: 6
                    rightMargin: 6
                }
                spacing: 4
                
                Text {
                    text: "\uf3c5"  // fa-location-dot
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 15
                    color: Theme.onAccentText
                }
                
                Text {
                    text: weatherWidget.location
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.onAccentText
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                    font.pixelSize: 15
                }
                
                // Refresh button
                Rectangle {
                    width: 22
                    height: 22
                    radius: 5
                    color: refreshBtn.containsMouse ? weatherWidget.colorSecondary : Theme.onAccentText
                    
                    Text {
                        anchors.centerIn: parent
                        text: "\uf2f1"  // fa-rotate
                        font.family: "Font Awesome 6 Free Solid"
                        font.weight: Font.Black
                        font.pixelSize: 13
                        color: refreshBtn.containsMouse ? Theme.onAccentText : weatherWidget.colorAccent
                        
                        RotationAnimation on rotation {
                            running: weatherProcess.running
                            from: 0
                            to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                    
                    MouseArea {
                        id: refreshBtn
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!weatherProcess.running) {
                                weatherProcess.running = true
                            }
                        }
                    }
                }
            }
        }
        
        // Main weather display - compact
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            
            // Weather icon - smaller
            Rectangle {
                Layout.preferredWidth: 72
                Layout.preferredHeight: 72
                Layout.alignment: Qt.AlignVCenter
                radius: 8
                color: weatherWidget.colorMain
                border.width: 1
                border.color: Theme.border
                opacity: 0.9
                
                Text {
                    anchors.centerIn: parent
                    text: weatherWidget.weatherIcon
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 36
                    color: Theme.text
                    
                    // Subtle floating animation
                    SequentialAnimation on y {
                        running: true
                        loops: Animation.Infinite
                        NumberAnimation { from: 0; to: -2; duration: 2000; easing.type: Easing.InOutSine }
                        NumberAnimation { from: -2; to: 0; duration: 2000; easing.type: Easing.InOutSine }
                    }
                }
            }
            
            // Temperature and condition
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                
                // Temperature
                Text {
                    text: weatherWidget.temperature
                    font.pixelSize: 32
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.text
                }
                
                // Condition
                Text {
                    text: weatherWidget.condition
                    font.pixelSize: 15
                    font.family: "JetBrains Mono"
                    color: Theme.muted
                    elide: Text.ElideRight
                    Layout.fillWidth: true
                }
                
                // Feels like
                Text {
                    text: "Feels " + weatherWidget.feelsLike
                    font.pixelSize: 14
                    font.family: "JetBrains Mono"
                    color: Theme.muted2
                    opacity: 0.8
                    visible: weatherWidget.feelsLike !== "--"
                }
            }
        }
        
        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: Theme.border
            opacity: 0.3
        }
        
        // Bottom stats row - compact
        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            
            // Wind stat box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 4
                color: weatherWidget.colorMain
                border.width: 1
                border.color: Theme.border
                opacity: 0.8
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        text: "\uf72e"  // fa-wind
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 17
                        color: Theme.muted
                    }
                    
                    Text {
                        text: weatherWidget.windSpeed
                        font.pixelSize: 15
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: Theme.text
                    }
                }
            }
            
            // Humidity stat box
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                radius: 4
                color: weatherWidget.colorMain
                border.width: 1
                border.color: Theme.border
                opacity: 0.8
                
                RowLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    
                    Text {
                        text: "\uf043"  // fa-droplet
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 17
                        color: Theme.muted
                    }
                    
                    Text {
                        text: weatherWidget.humidity
                        font.pixelSize: 15
                        font.family: "JetBrains Mono"
                        font.bold: true
                        color: Theme.text
                    }
                }
            }
        }
    }
}
