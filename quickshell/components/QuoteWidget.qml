// QuoteWidget.qml
// Displays a random inspirational quote
// Theme: DARK with light accent header strip
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import ".."

Rectangle {
    id: quoteWidget
    
    // Color scheme - solid colors for inner widgets
    readonly property color colorMain: Theme.surface
    readonly property color colorMainLight: Theme.surface2
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorAccentDim: Theme.accent2
    readonly property color colorSecondary: Theme.secondary
    readonly property color colorSecondary2: Theme.muted
    readonly property color colorCyan: Theme.muted
    readonly property color colorYellow: Theme.secondaryStrong
    readonly property Gradient widgetGradient: Gradient {
        GradientStop { position: 0.0; color: Theme.bg }
        GradientStop { position: 0.51; color: Theme.surface }
        GradientStop { position: 1.0; color: Theme.border }
    }
    
    property string quoteText: "Loading wisdom..."
    property string quoteAuthor: ""
    
    // Collection of quotes (fallback if API fails)
    property var localQuotes: [
        { text: "The only way to do great work is to love what you do.", author: "Steve Jobs" },
        { text: "In the middle of difficulty lies opportunity.", author: "Albert Einstein" },
        { text: "Simplicity is the ultimate sophistication.", author: "Leonardo da Vinci" },
        { text: "The best time to plant a tree was 20 years ago. The second best time is now.", author: "Chinese Proverb" },
        { text: "Stay hungry, stay foolish.", author: "Steve Jobs" },
        { text: "Code is like humor. When you have to explain it, it's bad.", author: "Cory House" },
        { text: "First, solve the problem. Then, write the code.", author: "John Johnson" },
        { text: "Experience is the name everyone gives to their mistakes.", author: "Oscar Wilde" },
        { text: "The only true wisdom is in knowing you know nothing.", author: "Socrates" },
        { text: "Not all those who wander are lost.", author: "J.R.R. Tolkien" },
        { text: "Do what you can, with what you have, where you are.", author: "Theodore Roosevelt" },
        { text: "The journey of a thousand miles begins with a single step.", author: "Lao Tzu" },
        { text: "Be yourself; everyone else is already taken.", author: "Oscar Wilde" },
        { text: "The future belongs to those who believe in the beauty of their dreams.", author: "Eleanor Roosevelt" },
        { text: "It does not matter how slowly you go as long as you do not stop.", author: "Confucius" }
    ]
    
    function getRandomQuote() {
        let idx = Math.floor(Math.random() * localQuotes.length)
        quoteText = localQuotes[idx].text
        quoteAuthor = localQuotes[idx].author
    }
    
    radius: 4
    
    // DARK theme - solid main surface
    clip: true
    color: quoteWidget.colorMain
    
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
    border.color: Theme.border
    
    Component.onCompleted: getRandomQuote()
    
    // Refresh quote every 30 minutes
    Timer {
        interval: 1800000
        running: true
        repeat: true
        onTriggered: quoteWidget.getRandomQuote()
    }
    
    // Compact header strip
    Rectangle {
        id: quoteHeader
        anchors {
            top: parent.top
            left: parent.left
            right: parent.right
            margins: 1
        }
        height: 22
        radius: 4
        color: quoteWidget.colorAccent
        
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
                text: "\uf10d"  // fa-quote-left
                font.family: "Font Awesome 6 Free Solid"
                font.weight: Font.Black
                font.pixelSize: 13
                color: Theme.onAccentText
            }
            
            Text {
                text: "Wisdom"
                font.pixelSize: 13
                font.family: "JetBrains Mono"
                font.bold: true
                color: Theme.onAccentText
            }
            
            Item { Layout.fillWidth: true }
            
            // Refresh button with spin animation
            Rectangle {
                id: refreshBtn
                width: 16
                height: 16
                radius: 4
                color: refreshQuoteBtn.containsMouse ? Theme.onAccentText : quoteWidget.colorMainLight
                
                Text {
                    id: refreshIcon
                    anchors.centerIn: parent
                    text: "\uf2f1"  // fa-rotate
                    font.family: "Font Awesome 6 Free Solid"
                    font.weight: Font.Black
                    font.pixelSize: 12
                    color: refreshQuoteBtn.containsMouse ? quoteWidget.colorAccent : Theme.muted
                    
                    // Spin animation on hover
                    rotation: refreshQuoteBtn.containsMouse ? 360 : 0
                    Behavior on rotation { NumberAnimation { duration: 400; easing.type: Easing.InOutQuad } }
                }
                
                MouseArea {
                    id: refreshQuoteBtn
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: quoteWidget.getRandomQuote()
                }
            }
        }
    }
    
    ColumnLayout {
        anchors {
            fill: parent
            margins: 6
            topMargin: 26
        }
        spacing: 2
        
        // Quote text
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.centerIn: parent
                width: parent.width
                spacing: 2
                
                Text {
                    Layout.fillWidth: true
                    text: "「" + quoteWidget.quoteText + "」"
                    font.pixelSize: 13
                    font.family: "JetBrains Mono"
                    color: Theme.text
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                    lineHeight: 1.2
                    elide: Text.ElideRight
                    maximumLineCount: 2
                }
                
                // Author
                Text {
                    Layout.fillWidth: true
                    text: "— " + quoteWidget.quoteAuthor
                    font.pixelSize: 9
                    font.family: "JetBrains Mono"
                    font.italic: true
                    color: Theme.muted
                    horizontalAlignment: Text.AlignRight
                }
            }
        }
    }
}
