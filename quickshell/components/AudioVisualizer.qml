// AudioVisualizer.qml
// 6-bar audio visualizer driven by the shared Pipewire service.
//
// The bar geometry is drawn by shaders/viz_bars.frag, a GLSL fragment shader
// ported from DankMaterialShell (MIT, Avenge Media LLC) - see ATTRIBUTION.md.
// The shader takes six 0..1 band levels and renders rounded bars; this widget
// supplies the levels from the pipewire peak data the rest of the shell reads.
import QtQuick

Item {
    id: visualizer

    // Six band levels in 0..1, supplied by the caller.
    property var bands: [0, 0, 0, 0, 0, 0]
    property color barColor: Theme.accent

    implicitWidth: 96
    implicitHeight: 28

    ShaderEffect {
        anchors.fill: parent
        // The fragment shader works in pixel space, so it needs the real size.
        property real widthPx: visualizer.width
        property real heightPx: visualizer.height
        property real minH: 2.0
        property real maxH: visualizer.height
        property real band0: clamp(visualizer.bands[0])
        property real band1: clamp(visualizer.bands[1])
        property real band2: clamp(visualizer.bands[2])
        property real band3: clamp(visualizer.bands[3])
        property real band4: clamp(visualizer.bands[4])
        property real band5: clamp(visualizer.bands[5])
        property color fillColor: visualizer.barColor

        function clamp(v) {
            if (v === undefined || v === null || isNaN(v)) return 0.0
            return v < 0 ? 0.0 : (v > 1 ? 1.0 : v)
        }

        // The shader's uniform block, in declaration order. Qt packs these
        // automatically; the names here are the block members in viz_bars.frag.
        fragmentShader: Qt.resolvedUrl("../shaders/viz_bars.frag")
    }
}
