import QtQuick
import QtQuick.Layouts
import Quickshell.Services.Pipewire
import qs.Components
import qs.Settings

Item {
    id: audioMenu

    property string speakerName: ""
    property string microphoneName: ""

    width: mainRow.width
    height: mainRow.height

    // Function to get device name
    function getDeviceName(device) {
        if (!device) return "No Device";
        return device.nickname || device.description || device.name || "Unknown";
    }

    // Update device names
    function updateDeviceNames() {
        speakerName = getDeviceName(Pipewire.defaultAudioSink);
        microphoneName = getDeviceName(Pipewire.defaultAudioSource);
    }

    Component.onCompleted: {
        updateDeviceNames();
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
            audioMenu.updateDeviceNames();
        }

        function onDefaultAudioSourceChanged() {
            audioMenu.updateDeviceNames();
        }

        function onReadyChanged() {
            if (Pipewire.ready) {
                audioMenu.updateDeviceNames();
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
                icon: "volume_up"
                text: speakerName
                pillColor: Theme.surfaceVariant
                iconCircleColor: Theme.accentPrimary
                iconTextColor: Theme.backgroundPrimary
                textColor: Theme.textPrimary
                collapsedIconColor: Theme.textPrimary
                autoHide: false
                showPill: true  // Always show the pill

                StyledTooltip {
                    text: "Output Device: " + speakerName
                    positionAbove: false
                    tooltipVisible: speakerMouseArea.containsMouse
                    targetItem: speakerPill
                    delay: 1500
                }

                MouseArea {
                    id: speakerMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (audioDeviceSelector.visible) {
                            audioDeviceSelector.dismiss();
                        } else {
                            audioDeviceSelector.tabIndex = 0; // Output tab
                            audioDeviceSelector.show();
                        }
                    }
                }
            }
        }

        // Microphone Section
        Item {
            id: microphoneSection
            width: microphonePill.width
            height: microphonePill.height

            PillIndicator {
                id: microphonePill
                icon: "mic"
                text: microphoneName
                pillColor: Theme.surfaceVariant
                iconCircleColor: Theme.accentPrimary
                iconTextColor: Theme.backgroundPrimary
                textColor: Theme.textPrimary
                collapsedIconColor: Theme.textPrimary
                autoHide: false
                showPill: true  // Always show the pill

                StyledTooltip {
                    text: "Input Device: " + microphoneName
                    positionAbove: false
                    tooltipVisible: microphoneMouseArea.containsMouse
                    targetItem: microphonePill
                    delay: 1500
                }

                MouseArea {
                    id: microphoneMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        if (audioDeviceSelector.visible) {
                            audioDeviceSelector.dismiss();
                        } else {
                            audioDeviceSelector.tabIndex = 1; // Input tab
                            audioDeviceSelector.show();
                        }
                    }
                }
            }
        }
    }

    // Audio Device Selector popup
    AudioDeviceSelector {
        id: audioDeviceSelector
        onPanelClosed: audioDeviceSelector.dismiss()
    }
}
