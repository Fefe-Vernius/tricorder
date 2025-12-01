import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Settings
import qs.Components

Item {
    id: root
    width: vpnActive ? 50 * Theme.scale(Screen) : 0
    height: vpnActive ? 22 * Theme.scale(Screen) : 0
    visible: vpnActive

    property bool vpnActive: false
    property string vpnType: ""
    property var activeInterfaces: []

    // Check VPN status on startup
    Component.onCompleted: {
        checkVpnStatus();
    }

    // Timer to periodically check VPN status
    Timer {
        id: vpnCheckTimer
        interval: 5000  // Check every 5 seconds
        running: true
        repeat: true
        onTriggered: checkVpnStatus()
    }

    // Function to check VPN status
    function checkVpnStatus() {
        vpnCheckProcess.running = true;
    }

    // Process to check for VPN interfaces using ip command
    Process {
        id: vpnCheckProcess
        running: false
        command: ["sh", "-c", "ip -brief link show 2>/dev/null || nmcli -t -f DEVICE,TYPE,STATE device 2>/dev/null || ls /sys/class/net/ 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                const lines = text.split("\n");
                let foundVpn = false;
                let interfaces = [];
                let types = new Set();

                for (let i = 0; i < lines.length; ++i) {
                    const line = lines[i].trim();
                    if (!line) continue;

                    // Check if line is from 'ip -brief' output (contains whitespace)
                    if (line.includes(" ") || line.includes("\t")) {
                        // Parse ip -brief output or nmcli output
                        const parts = line.split(/[\s:]+/);
                        if (parts.length < 2) continue;

                        const iface = parts[0];
                        const state = parts[1];

                        // Check if interface is UP and is a VPN interface
                        if (state === "UP" || state === "UNKNOWN" || state === "connected") {
                            checkVpnInterface(iface, interfaces, types);
                        }
                    } else {
                        // Single word per line - likely from ls /sys/class/net/
                        // We need to check if it's UP by reading the operstate file
                        checkVpnInterface(line, interfaces, types);
                    }
                }

                root.vpnActive = interfaces.length > 0;
                root.activeInterfaces = interfaces;

                // Set VPN type label
                if (types.size > 1) {
                    root.vpnType = "Multiple VPN types";
                } else if (types.size === 1) {
                    root.vpnType = Array.from(types)[0];
                } else {
                    root.vpnType = "";
                }
            }
        }
    }

    // Helper function to check if an interface is a VPN interface
    function checkVpnInterface(iface, interfaces, types) {
        // Check for wireguard interfaces (wg*)
        if (iface.startsWith("wg")) {
            if (!interfaces.includes(iface)) {
                interfaces.push(iface);
                types.add("WireGuard");
            }
        }
        // Check for OpenVPN interfaces (tun*, tap*)
        else if (iface.startsWith("tun") || iface.startsWith("tap")) {
            if (!interfaces.includes(iface)) {
                interfaces.push(iface);
                types.add("OpenVPN");
            }
        }
    }

    // VPN indicator - box with "VPN" text
    Rectangle {
        id: vpnBox
        anchors.centerIn: parent
        width: 42 * Theme.scale(Screen)
        height: 20 * Theme.scale(Screen)
        radius: 4
        color: "transparent"
        border.color: vpnMouseArea.containsMouse ? Theme.accentPrimary : Theme.textPrimary
        border.width: 1.5

        Text {
            id: vpnText
            anchors.centerIn: parent
            text: "VPN"
            font.family: "monospace"
            font.pixelSize: 11 * Theme.scale(Screen)
            font.bold: true
            color: vpnMouseArea.containsMouse ? Theme.accentPrimary : Theme.textPrimary
        }

        MouseArea {
            id: vpnMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onEntered: vpnTooltip.tooltipVisible = true
            onExited: vpnTooltip.tooltipVisible = false
        }
    }

    StyledTooltip {
        id: vpnTooltip
        text: {
            if (activeInterfaces.length === 0) {
                return "VPN Active";
            } else if (activeInterfaces.length === 1) {
                return vpnType + " Active: " + activeInterfaces[0];
            } else {
                return vpnType + " Active: " + activeInterfaces.join(", ");
            }
        }
        positionAbove: false
        tooltipVisible: false
        targetItem: vpnBox
        delay: 200
    }
}
