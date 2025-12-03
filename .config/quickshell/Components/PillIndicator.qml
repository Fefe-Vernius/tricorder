import QtQuick
import QtQuick.Controls
import qs.Settings

Item {
    id: revealPill

    // External properties
    property string icon: ""
    property string text: ""
    property color pillColor: Theme.surfaceVariant
    property color textColor: Theme.textPrimary
    property color iconCircleColor: Theme.accentPrimary
    property color iconTextColor: Theme.backgroundPrimary
    property color collapsedIconColor: Theme.textPrimary
    property int pillHeight: 22 * Theme.scale(Screen)
    property int iconSize: 22 * Theme.scale(Screen)
    property int pillPaddingHorizontal: 14
    property bool autoHide: false
    property string iconPosition: "right" // "right" or "left"
    property bool showVolumeFill: false
    property real volumeFill: 0 // 0-100
    property color volumeFillColor: Theme.accentPrimary
    property real minPillWidth: 0 // Minimum pill width to prevent resizing

    // Internal state
    property bool showPill: false
    property bool shouldAnimateHide: false

    // Exposed width logic
    readonly property int pillOverlap: iconSize / 2
    readonly property int maxPillWidth: Math.max(
        minPillWidth > 0 ? minPillWidth : 1,
        textItem.implicitWidth + pillPaddingHorizontal * 2 + pillOverlap
    )

    signal shown
    signal hidden

    width: iconSize + (showPill ? maxPillWidth - pillOverlap : 0)
    height: pillHeight

    Rectangle {
        id: pill
        width: showPill ? maxPillWidth : 1
        height: pillHeight
        x: iconPosition === "left" ? (iconCircle.x + iconCircle.width / 2) : (iconCircle.x + iconCircle.width / 2) - width
        opacity: showPill ? 1 : 0
        color: pillColor
        topLeftRadius: iconPosition === "left" ? 0 : pillHeight / 2
        bottomLeftRadius: iconPosition === "left" ? 0 : pillHeight / 2
        topRightRadius: iconPosition === "left" ? pillHeight / 2 : 0
        bottomRightRadius: iconPosition === "left" ? pillHeight / 2 : 0
        anchors.verticalCenter: parent.verticalCenter
        clip: true

        Rectangle {
            id: volumeFillRect
            visible: showVolumeFill && showPill
            height: parent.height
            width: parent.width * (volumeFill / 100)
            color: volumeFillColor
            opacity: 0.3
            anchors.left: iconPosition === "left" ? parent.right : undefined
            anchors.right: iconPosition === "right" ? parent.left : undefined
            x: iconPosition === "left" ? parent.width - width : 0
            topLeftRadius: iconPosition === "left" ? 0 : pillHeight / 2
            bottomLeftRadius: iconPosition === "left" ? 0 : pillHeight / 2
            topRightRadius: iconPosition === "left" ? pillHeight / 2 : 0
            bottomRightRadius: iconPosition === "left" ? pillHeight / 2 : 0

            Behavior on width {
                NumberAnimation {
                    duration: 100
                    easing.type: Easing.OutCubic
                }
            }
        }

        Text {
            id: textItem
            anchors.centerIn: parent
            text: revealPill.text
            font.pixelSize: Theme.fontSizeSmall * Theme.scale(Screen)
            font.family: Theme.fontFamily
            font.weight: Font.Bold
            color: textColor
            visible: showPill
        }

        Behavior on width {
            enabled: showAnim.running || hideAnim.running
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
        Behavior on opacity {
            enabled: showAnim.running || hideAnim.running
            NumberAnimation {
                duration: 250
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: iconCircle
        width: iconSize
        height: iconSize
        radius: width / 2
        color: showPill ? iconCircleColor : "transparent"
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: iconPosition === "left" ? parent.left : undefined
        anchors.right: iconPosition === "right" ? parent.right : undefined

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.InOutQuad
            }
        }

        Text {
            anchors.centerIn: parent
            font.family: showPill ? "Material Symbols Rounded" : "Material Symbols Outlined"
            font.pixelSize: Theme.fontSizeSmall * Theme.scale(Screen)
            text: revealPill.icon
            color: showPill ? iconTextColor : collapsedIconColor
        }
    }

    ParallelAnimation {
        id: showAnim
        running: false
        NumberAnimation {
            target: pill
            property: "width"
            from: 1
            to: maxPillWidth
            duration: 250
            easing.type: Easing.OutCubic
        }
        NumberAnimation {
            target: pill
            property: "opacity"
            from: 0
            to: 1
            duration: 250
            easing.type: Easing.OutCubic
        }
        onStarted: {
            showPill = true;
        }
        onStopped: {
            delayedHideAnim.start();
            shown();
        }
    }

    SequentialAnimation {
        id: delayedHideAnim
        running: false
        PauseAnimation {
            duration: 2500
        }
        ScriptAction {
            script: if (shouldAnimateHide)
                hideAnim.start()
        }
    }

    ParallelAnimation {
        id: hideAnim
        running: false
        NumberAnimation {
            target: pill
            property: "width"
            from: maxPillWidth
            to: 1
            duration: 250
            easing.type: Easing.InCubic
        }
        NumberAnimation {
            target: pill
            property: "opacity"
            from: 1
            to: 0
            duration: 250
            easing.type: Easing.InCubic
        }
        onStopped: {
            showPill = false;
            shouldAnimateHide = false;
            hidden();
        }
    }

    function show() {
        if (!showPill) {
            shouldAnimateHide = autoHide;
            showAnim.start();
        } else {
            hideAnim.stop();
            delayedHideAnim.restart();
        }
    }

    function hide() {
        if (showPill) {
            hideAnim.start();
        }
        showTimer.stop();
    }

    function showDelayed() {
        if (!showPill) {
            shouldAnimateHide = autoHide;
            showTimer.start();
        } else {
            hideAnim.stop();
            delayedHideAnim.restart();
        }
    }

    Timer {
        id: showTimer
        interval: 500
        onTriggered: {
            if (!showPill) {
                showAnim.start();
            }
        }
    }
}