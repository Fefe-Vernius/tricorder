import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Settings
import qs.Components

Item {
    id: root
    width: 22
    height: 22

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

    // VPN indicator icon
    Item {
        id: vpnIcon
        width: 22; height: 22

        Text {
            id: vpnText
            anchors.centerIn: parent
            text: vpnActive ? "vpn_key" : "vpn_key_off"
            font.family: vpnMouseArea.containsMouse ? "Material Symbols Rounded" : "Material Symbols Outlined"
            font.pixelSize: 16 * Theme.scale(Screen)
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
            if (!vpnActive) {
                return "VPN Inactive";
            } else if (activeInterfaces.length === 1) {
                return vpnType + " Active: " + activeInterfaces[0];
            } else if (activeInterfaces.length > 1) {
                return vpnType + " Active: " + activeInterfaces.join(", ");
            } else {
                return "VPN Active";
            }
        }
        positionAbove: false
        tooltipVisible: false
        targetItem: vpnIcon
        delay: 200
    }
}
