// MediaPlayerWidget.qml
// Media player with album art, controls, and progress bar using MPRIS
// Theme: DARK with subtle light header accent (alternating pattern)
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Services.Mpris
import ".."

Rectangle {
    id: mediaPlayer
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.accent
    readonly property color colorAccent: Theme.accent
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondaryStrong
    readonly property color colorSecondary2: Theme.border
    readonly property color colorCyan: Theme.accentStrong
    readonly property color colorYellow: Theme.accentStrong
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    // Light accent strip on top
    property bool hasLightAccent: true
    
    // Get the active media player
    property var player: Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
    property bool hasPlayer: player !== null
    property bool isPlaying: hasPlayer && player.playbackState === MprisPlaybackState.Playing
    
    // Track info
    property string trackTitle: hasPlayer && player.trackTitle ? player.trackTitle : "No media playing"
    property string trackArtist: hasPlayer && player.trackArtist ? player.trackArtist : ""
    property string trackAlbum: hasPlayer && player.trackAlbum ? player.trackAlbum : ""
    property string artUrl: hasPlayer && player.trackArtUrl ? player.trackArtUrl : ""
    
    // MPRIS position/length - need to poll for position updates
    property real positionSecs: 0
    property real durationSecs: hasPlayer && player.length ? player.length : 0
    
    // Update position from player
    function updatePosition() {
        if (hasPlayer) {
            positionSecs = player.position
        }
    }
    
    // Timer to poll position (MPRIS doesn't always push updates)
    Timer {
        interval: 500
        running: mediaPlayer.isPlaying
        repeat: true
        onTriggered: mediaPlayer.updatePosition()
    }
    
    // Also update when player changes
    onPlayerChanged: updatePosition()
    onHasPlayerChanged: updatePosition()
    Component.onCompleted: updatePosition()
    
    radius: 8
    clip: true
    color: mediaPlayer.colorMain

    border.width: 1
    border.color: Theme.border
    
    // Compact header strip
    Rectangle {
        id: headerAccent
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 30
        radius: 4
        
        // Light blue accent header
        color: mediaPlayer.colorAccent
        
        // Bottom corners square off
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
                text: "\uf001"  // fa-music
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 13
                color: Theme.onAccentText
            }
            
            Text {
                text: "Media"
                font.pixelSize: 15
                font.family: "JetBrains Mono"
                font.bold: true
                color: Theme.onAccentText
            }
            
            Item { Layout.fillWidth: true }

            // Ported DankMaterialShell audio visualizer (MIT). Six bars driven
            // by a play/pause-flavoured idle animation until real peak data is
            // available; see components/AudioVisualizer.qml.
            AudioVisualizer {
                id: mediaViz
                Layout.preferredWidth: 72
                Layout.preferredHeight: 20
                Layout.alignment: Qt.AlignVCenter
                barColor: mediaPlayer.hasPlayer ? mediaPlayer.colorMainLight : mediaPlayer.colorSecondary2

                property real phase: 0
                NumberAnimation on phase {
                    running: mediaPlayer.isPlaying
                    from: 0; to: Math.PI * 2
                    duration: 1400
                    loops: Animation.Infinite
                }
                bands: mediaPlayer.isPlaying ? [
                    Math.abs(Math.sin(phase + 0.0)),
                    Math.abs(Math.sin(phase + 0.7)),
                    Math.abs(Math.sin(phase + 1.4)),
                    Math.abs(Math.sin(phase + 2.1)),
                    Math.abs(Math.sin(phase + 2.8)),
                    Math.abs(Math.sin(phase + 3.5))
                ] : [0.08, 0.05, 0.08, 0.05, 0.08, 0.05]
            }
            
            // Player name indicator
            Text {
                text: mediaPlayer.hasPlayer ? mediaPlayer.player.identity : ""
                font.pixelSize: 15
                font.family: "JetBrains Mono"
                color: Theme.onAccentText
                opacity: 0.8
            }
        }
    }
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 12
            topMargin: 40  // Account for header accent
        }
        spacing: 6
        
        // Album art and track info
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12
            
            // Album art - compact
            Item {
                Layout.preferredWidth: 76
                Layout.preferredHeight: 76
                Layout.alignment: Qt.AlignVCenter
                
                Rectangle {
                    anchors.centerIn: parent
                    width: 76
                    height: 76
                    radius: 6
                    color: mediaPlayer.colorSecondary2
                    clip: true
                    
                    Image {
                        anchors.fill: parent
                        source: mediaPlayer.artUrl
                        fillMode: Image.PreserveAspectCrop
                        visible: mediaPlayer.artUrl !== ""
                    }
                    
                    // Placeholder icon when no art
                    Text {
                        anchors.centerIn: parent
                        text: "\uf001"  // fa-music
                        font.family: "Font Awesome 6 Free Solid"
                        font.pixelSize: 28
                        color: mediaPlayer.colorSecondary2
                        opacity: 0.5
                        visible: mediaPlayer.artUrl === ""
                    }
                }
            }
            
            // Track info - vertically centered
            ColumnLayout {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                spacing: 2
                
                Text {
                    Layout.fillWidth: true
                    text: mediaPlayer.trackTitle
                    font.pixelSize: 14
                    font.family: "JetBrains Mono"
                    font.bold: true
                    color: Theme.accentStrong
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }
                
                Text {
                    Layout.fillWidth: true
                    text: mediaPlayer.trackArtist
                    font.pixelSize: 13
                    font.family: "JetBrains Mono"
                    color: mediaPlayer.colorCyan
                    elide: Text.ElideRight
                    visible: mediaPlayer.trackArtist !== ""
                }
                
                Text {
                    Layout.fillWidth: true
                    text: mediaPlayer.trackAlbum
                    font.pixelSize: 12
                    font.family: "JetBrains Mono"
                    color: mediaPlayer.colorSecondary2
                    opacity: 0.7
                    elide: Text.ElideRight
                    visible: mediaPlayer.trackAlbum !== ""
                }
            }
        }
        
        // Progress bar
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            
            // Clickable progress bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                radius: 3
                color: mediaPlayer.colorSecondary2
                
                Rectangle {
                    width: mediaPlayer.durationSecs > 0 ? (mediaPlayer.positionSecs / mediaPlayer.durationSecs) * parent.width : 0
                    height: parent.height
                    radius: parent.radius
                    color: mediaPlayer.colorSecondary
                    
                    Behavior on width {
                        NumberAnimation { duration: 100 }
                    }
                }
                
                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: mouse => {
                        if (mediaPlayer.hasPlayer && mediaPlayer.durationSecs > 0) {
                            let newPos = (mouse.x / width) * mediaPlayer.durationSecs
                            mediaPlayer.player.position = newPos
                        }
                    }
                }
            }
            
            // Time display
            RowLayout {
                Layout.fillWidth: true
                
                Text {
                    text: formatTime(mediaPlayer.positionSecs)
                    font.pixelSize: 14
                    font.family: "JetBrains Mono"
                    color: mediaPlayer.colorSecondary2
                }
                
                Item { Layout.fillWidth: true }
                
                Text {
                    text: formatTime(mediaPlayer.durationSecs)
                    font.pixelSize: 14
                    font.family: "JetBrains Mono"
                    color: mediaPlayer.colorSecondary2
                }
            }
        }
        
        // Compact Controls
        RowLayout {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignHCenter
            spacing: 10
            
            // Previous track
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: controlPrev.containsMouse ? mediaPlayer.colorSecondary2 : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf048"  // fa-step-backward
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 12
                    color: mediaPlayer.colorSecondary
                }
                
                MouseArea {
                    id: controlPrev
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaPlayer.hasPlayer) mediaPlayer.player.previous()
                    }
                }
            }
            
            // Backward 10s
            Rectangle {
                width: 30
                height: 30
                radius: 6
                color: controlBack.containsMouse ? mediaPlayer.colorSecondary2 : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf04a"  // fa-backward
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 11
                    color: mediaPlayer.colorCyan
                }
                
                MouseArea {
                    id: controlBack
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaPlayer.hasPlayer) {
                            let newPos = Math.max(0, mediaPlayer.positionSecs - 10)
                            mediaPlayer.player.position = newPos
                        }
                    }
                }
            }
            
            // Play/Pause
            Rectangle {
                width: 38
                height: 38
                radius: 19
                color: controlPlay.containsMouse ? mediaPlayer.colorMainLight : mediaPlayer.colorSecondary2
                border.width: 2
                border.color: mediaPlayer.colorSecondary
                
                Text {
                    anchors.centerIn: parent
                    text: mediaPlayer.isPlaying ? "\uf04c" : "\uf04b"  // fa-pause / fa-play
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 15
                    color: Theme.accentStrong
                }
                
                MouseArea {
                    id: controlPlay
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaPlayer.hasPlayer) mediaPlayer.player.togglePlaying()
                    }
                }
            }
            
            // Forward 10s
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: controlFwd.containsMouse ? mediaPlayer.colorSecondary2 : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf04e"  // fa-forward
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 11
                    color: mediaPlayer.colorCyan
                }
                
                MouseArea {
                    id: controlFwd
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaPlayer.hasPlayer) {
                            let newPos = Math.min(mediaPlayer.durationSecs, mediaPlayer.positionSecs + 10)
                            mediaPlayer.player.position = newPos
                        }
                    }
                }
            }
            
            // Next track
            Rectangle {
                width: 30
                height: 30
                radius: 15
                color: controlNext.containsMouse ? mediaPlayer.colorSecondary2 : "transparent"
                
                Text {
                    anchors.centerIn: parent
                    text: "\uf051"  // fa-step-forward
                    font.family: "Font Awesome 6 Free Solid"
                    font.pixelSize: 12
                    color: mediaPlayer.colorSecondary
                }
                
                MouseArea {
                    id: controlNext
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (mediaPlayer.hasPlayer) mediaPlayer.player.next()
                    }
                }
            }
        }
    }
    
    // Helper function to format time
    function formatTime(secs) {
        if (isNaN(secs) || secs < 0) return "0:00"
        var mins = Math.floor(secs / 60)
        var s = Math.floor(secs % 60)
        return mins + ":" + (s < 10 ? "0" : "") + s
    }
}
