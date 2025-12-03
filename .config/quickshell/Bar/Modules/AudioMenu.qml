import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Components
import qs.Settings

Item {
    id: audioMenu

    property string speakerName: ""
    property string microphoneName: ""
    property int speakerVolume: 0
    property int microphoneVolume: 0
    property bool showingSpeakerVolume: false
    property bool showingMicrophoneVolume: false
    property real speakerNameWidth: 0
    property real microphoneNameWidth: 0

    width: mainRow.width
    height: mainRow.height

    // Function to get device name
    function getDeviceName(device) {
        if (!device) return "No Device";
        return device.nickname || device.description || device.name || "Unknown";
    }

    // Function to get device volume
    function getDeviceVolume(device) {
        if (!device || !device.audio) return 0;
        return Math.round(device.audio.volume * 100);
    }

    // Update device names and volumes
    function updateDeviceInfo() {
        speakerName = getDeviceName(Pipewire.defaultAudioSink);
        microphoneName = getDeviceName(Pipewire.defaultAudioSource);
        speakerVolume = getDeviceVolume(Pipewire.defaultAudioSink);
        microphoneVolume = getDeviceVolume(Pipewire.defaultAudioSource);
    }

    // Toggle mute for speaker
    function toggleSpeakerMute() {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            Pipewire.defaultAudioSink.audio.muted = !Pipewire.defaultAudioSink.audio.muted;
        }
    }

    // Toggle mute for microphone
    function toggleMicrophoneMute() {
        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
            Pipewire.defaultAudioSource.audio.muted = !Pipewire.defaultAudioSource.audio.muted;
        }
    }

    // Set speaker volume
    function setSpeakerVolume(volume) {
        if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
            var clampedVolume = Math.max(0, Math.min(100, volume));
            Pipewire.defaultAudioSink.audio.volume = clampedVolume / 100.0;
            speakerVolume = clampedVolume;
        }
    }

    // Set microphone volume
    function setMicrophoneVolume(volume) {
        if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
            var clampedVolume = Math.max(0, Math.min(100, volume));
            Pipewire.defaultAudioSource.audio.volume = clampedVolume / 100.0;
            microphoneVolume = clampedVolume;
        }
    }

    Component.onCompleted: {
        updateDeviceInfo();
    }

    // Bind all Pipewire nodes so their properties are valid
    PwObjectTracker {
        id: nodeTracker
        objects: Pipewire.nodes
    }

    // Monitor changes to default devices
    Connections {
        target: Pipewire

        function onDefaultAudioSinkChanged() {
            audioMenu.updateDeviceInfo();
        }

        function onDefaultAudioSourceChanged() {
            audioMenu.updateDeviceInfo();
        }

        function onReadyChanged() {
            if (Pipewire.ready) {
                audioMenu.updateDeviceInfo();
            }
        }
    }

    // Monitor volume changes
    Connections {
        target: Pipewire.defaultAudioSink ? Pipewire.defaultAudioSink.audio : null
        function onVolumeChanged() {
            if (Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio) {
                speakerVolume = Math.round(Pipewire.defaultAudioSink.audio.volume * 100);
            }
        }
    }

    Connections {
        target: Pipewire.defaultAudioSource ? Pipewire.defaultAudioSource.audio : null
        function onVolumeChanged() {
            if (Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio) {
                microphoneVolume = Math.round(Pipewire.defaultAudioSource.audio.volume * 100);
            }
        }
    }

    Row {
        id: mainRow
        spacing: 8 * Theme.scale(Screen)

        // Speaker Section
        Item {
            id: speakerSection
            width: speakerPill.width
            height: speakerPill.height

            PillIndicator {
                id: speakerPill
                icon: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted ? "volume_off" : "volume_up"
                text: showingSpeakerVolume ? speakerVolume + "%" : speakerName
                pillColor: Theme.surfaceVariant
                iconCircleColor: Theme.accentPrimary
                iconTextColor: Theme.backgroundPrimary
                textColor: Theme.textPrimary
                collapsedIconColor: Theme.textPrimary
                autoHide: false
                showPill: true
                iconPosition: "left"
                showVolumeFill: showingSpeakerVolume
                volumeFill: speakerVolume
                volumeFillColor: Theme.accentPrimary
                minPillWidth: speakerNameWidth > 0 ? speakerNameWidth + pillPaddingHorizontal * 2 + pillOverlap : 0

                // Measure the device name width when it changes
                onTextChanged: {
                    if (!showingSpeakerVolume && text !== "") {
                        speakerNameWidth = textMetrics.width;
                    }
                }
            }

            // Text metrics to measure device name width
            TextMetrics {
                id: textMetrics
                font.pixelSize: Theme.fontSizeSmall * Theme.scale(Screen)
                font.family: Theme.fontFamily
                font.weight: Font.Bold
                text: speakerName
            }

            // Icon click area - for mute/unmute
            MouseArea {
                id: speakerIconArea
                width: speakerPill.iconSize
                height: speakerPill.iconSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    audioMenu.toggleSpeakerMute();
                }
            }

            // Pill click area - for device selector
            MouseArea {
                id: speakerPillArea
                anchors.fill: parent
                anchors.leftMargin: speakerPill.iconSize
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (audioDeviceSelector.visible) {
                        audioDeviceSelector.dismiss();
                    } else {
                        audioDeviceSelector.tabIndex = 0;
                        audioDeviceSelector.show();
                    }
                }
            }

            // Scroll area - for volume adjustment
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    let step = 5;
                    if (wheel.angleDelta.y > 0) {
                        audioMenu.setSpeakerVolume(speakerVolume + step);
                    } else if (wheel.angleDelta.y < 0) {
                        audioMenu.setSpeakerVolume(speakerVolume - step);
                    }
                    showingSpeakerVolume = true;
                    speakerVolumeTimer.restart();
                }
            }

            Timer {
                id: speakerVolumeTimer
                interval: 2000
                onTriggered: {
                    showingSpeakerVolume = false;
                }
            }

            StyledTooltip {
                text: "Output: " + speakerName + " (" + speakerVolume + "%)\nLeft click icon to mute/unmute\nLeft click name to change device\nScroll to adjust volume"
                positionAbove: false
                tooltipVisible: (speakerIconArea.containsMouse || speakerPillArea.containsMouse) && !audioDeviceSelector.visible
                targetItem: speakerPill
                delay: 1500
            }
        }

        // Microphone Section
        Item {
            id: microphoneSection
            width: microphonePill.width
            height: microphonePill.height

            PillIndicator {
                id: microphonePill
                icon: Pipewire.defaultAudioSource && Pipewire.defaultAudioSource.audio && Pipewire.defaultAudioSource.audio.muted ? "mic_off" : "mic"
                text: showingMicrophoneVolume ? microphoneVolume + "%" : microphoneName
                pillColor: Theme.surfaceVariant
                iconCircleColor: Theme.accentPrimary
                iconTextColor: Theme.backgroundPrimary
                textColor: Theme.textPrimary
                collapsedIconColor: Theme.textPrimary
                autoHide: false
                showPill: true
                iconPosition: "left"
                showVolumeFill: showingMicrophoneVolume
                volumeFill: microphoneVolume
                volumeFillColor: Theme.accentPrimary
                minPillWidth: microphoneNameWidth > 0 ? microphoneNameWidth + pillPaddingHorizontal * 2 + pillOverlap : 0

                // Measure the device name width when it changes
                onTextChanged: {
                    if (!showingMicrophoneVolume && text !== "") {
                        microphoneNameWidth = micTextMetrics.width;
                    }
                }
            }

            // Text metrics to measure device name width
            TextMetrics {
                id: micTextMetrics
                font.pixelSize: Theme.fontSizeSmall * Theme.scale(Screen)
                font.family: Theme.fontFamily
                font.weight: Font.Bold
                text: microphoneName
            }

            // Icon click area - for mute/unmute
            MouseArea {
                id: microphoneIconArea
                width: microphonePill.iconSize
                height: microphonePill.iconSize
                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    audioMenu.toggleMicrophoneMute();
                }
            }

            // Pill click area - for device selector
            MouseArea {
                id: microphonePillArea
                anchors.fill: parent
                anchors.leftMargin: microphonePill.iconSize
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton
                onClicked: {
                    if (audioDeviceSelector.visible) {
                        audioDeviceSelector.dismiss();
                    } else {
                        audioDeviceSelector.tabIndex = 1;
                        audioDeviceSelector.show();
                    }
                }
            }

            // Scroll area - for volume adjustment
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
                propagateComposedEvents: true
                onWheel: (wheel) => {
                    let step = 5;
                    if (wheel.angleDelta.y > 0) {
                        audioMenu.setMicrophoneVolume(microphoneVolume + step);
                    } else if (wheel.angleDelta.y < 0) {
                        audioMenu.setMicrophoneVolume(microphoneVolume - step);
                    }
                    showingMicrophoneVolume = true;
                    microphoneVolumeTimer.restart();
                }
            }

            Timer {
                id: microphoneVolumeTimer
                interval: 2000
                onTriggered: {
                    showingMicrophoneVolume = false;
                }
            }

            StyledTooltip {
                text: "Input: " + microphoneName + " (" + microphoneVolume + "%)\nLeft click icon to mute/unmute\nLeft click name to change device\nScroll to adjust volume"
                positionAbove: false
                tooltipVisible: (microphoneIconArea.containsMouse || microphonePillArea.containsMouse) && !audioDeviceSelector.visible
                targetItem: microphonePill
                delay: 1500
            }
        }
    }

    // Audio Device Selector popup
    AudioDeviceSelector {
        id: audioDeviceSelector
        menuPosition: "left"
        onPanelClosed: audioDeviceSelector.dismiss()
    }
}
