// ClockWidget.qml
// Compact clock widget for the vertical bar
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import ".."

Rectangle {
    id: clockWidget
    
    readonly property color colorMain: Theme.surface
    readonly property color colorAccent: Theme.accentStrong
    readonly property color colorSecondary: Theme.secondaryStrong
    
    implicitWidth: 36
    implicitHeight: 36
    color: "transparent"
    
    ColumnLayout {
        anchors.centerIn: parent
        spacing: -2
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: Time.time.split(" ")[0] // Just the date part for a hint? No, let's show time
            font.pixelSize: 10
            font.family: "JetBrains Mono"
            font.bold: true
            color: clockWidget.colorAccent
        }
        
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: "\uf073"
            font.family: "Font Awesome 6 Free"
            font.pixelSize: 10
            color: clockWidget.colorSecondary
        }
    }
    
    ToolTip {
        id: clockToolTip
        text: Time.time
        delay: 500
        visible: mouseArea.containsMouse
    }
    
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
    }
}
