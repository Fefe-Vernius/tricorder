import QtQuick
import Quickshell
import Quickshell.Services.UPower
import Quickshell.Io
import QtQuick.Layouts
import qs.Components
import qs.Settings
import "../../Helpers/Time.js" as Time

Item {
    id: batteryWidget

    // Test mode
    property bool testMode: false
    property int testPercent: 49
    property bool testCharging: true

    property var battery: UPower.displayDevice
    property bool isReady: testMode ? true : (battery && battery.ready && battery.isLaptopBattery && battery.isPresent)
    property real percent: testMode ? testPercent : (isReady ? (battery.percentage * 100) : 0)
    property bool charging: testMode ? testCharging : (isReady ? battery.state === UPowerDeviceState.Charging : false)
    property bool show: isReady && percent > 0

    // Notification tracking
    property bool notified20: false
    property bool notified10: false

    // Monitor battery percentage and send notifications
    onPercentChanged: {
        if (!charging && isReady) {
            // 20% notification
            if (percent <= 20 && percent > 10 && !notified20) {
                Process.exec("notify-send", ["-u", "critical", "Low Battery", "Battery level at " + Math.round(percent) + "%"]);
                notified20 = true;
            }
            // 10% notification
            else if (percent <= 10 && !notified10) {
                Process.exec("notify-send", ["-u", "critical", "Critical Battery", "Battery level at " + Math.round(percent) + "%"]);
                notified10 = true;
            }
            // Reset flags when charging or battery increases
            else if (percent > 20) {
                notified20 = false;
                notified10 = false;
            }
        }
        // Reset notification flags when charging
        if (charging) {
            notified20 = false;
            notified10 = false;
        }
    }

    // Choose icon based on charge and charging state
    function batteryIcon() {
        if (!show)
            return "";

        // Charging icons
        if (charging) {
            if (percent >= 98)
                return "battery_charging_full";
            if (percent >= 90)
                return "battery_charging_90";
            if (percent >= 80)
                return "battery_charging_80";
            if (percent >= 60)
                return "battery_charging_60";
            if (percent >= 50)
                return "battery_charging_50";
            if (percent >= 30)
                return "battery_charging_30";
            if (percent >= 20)
                return "battery_charging_20";
            return "battery_error";
        }

        // Discharging icons - vertical battery with bars
        if (percent >= 90)
            return "battery_full";
        if (percent >= 77)
            return "battery_6_bar";
        if (percent >= 64)
            return "battery_5_bar";
        if (percent >= 51)
            return "battery_4_bar";
        if (percent >= 38)
            return "battery_3_bar";
        if (percent >= 25)
            return "battery_2_bar";
        if (percent >= 12)
            return "battery_1_bar";
        return "battery_0_bar";
    }

    visible: testMode || (isReady && battery.isLaptopBattery)
    width: batteryIcon.width
    height: batteryIcon.height

    Text {
        id: batteryIcon
        text: batteryWidget.batteryIcon()
        font.family: "Material Symbols Rounded"
        font.pixelSize: 16 * Theme.scale(Quickshell.screens[0])
        color: {
            if (mouseAreaBattery.containsMouse)
                return Theme.accentPrimary;
            if (!charging && percent <= 20)
                return "#d45151";
            return Theme.textPrimary;
        }

        MouseArea {
            id: mouseAreaBattery
            anchors.fill: parent
            hoverEnabled: true
            onEntered: {
                batteryTooltip.tooltipVisible = true;
            }
            onExited: {
                batteryTooltip.tooltipVisible = false;
            }
        }
    }

    StyledTooltip {
        id: batteryTooltip
        positionAbove: false
        text: {
            let lines = [];
            if (!batteryWidget.isReady) {
                return "";
            }

            // Add percentage as first line
            lines.push("Charge: " + Math.round(batteryWidget.percent) + "%");

            if (batteryWidget.battery.timeToEmpty > 0) {
                lines.push("Time left: " + Time.formatVagueHumanReadableTime(batteryWidget.battery.timeToEmpty));
            }

            if (batteryWidget.battery.timeToFull > 0) {
                lines.push("Time until full: " + Time.formatVagueHumanReadableTime(batteryWidget.battery.timeToFull));
            }

            if (batteryWidget.battery.changeRate !== undefined) {
                const rate = batteryWidget.battery.changeRate;
                if (rate > 0) {
                    lines.push(batteryWidget.charging ? "Charging rate: " + rate.toFixed(2) + " W" : "Discharging rate: " + rate.toFixed(2) + " W");
                }
                else if (rate < 0) {
                    lines.push("Discharging rate: " + Math.abs(rate).toFixed(2) + " W");
                }
                else {
                    lines.push("Estimating...");
                }
            }
            else {
                lines.push(batteryWidget.charging ? "Charging" : "Discharging");
            }

            if (batteryWidget.battery.healthPercentage !== undefined && batteryWidget.battery.healthPercentage > 0) {
                lines.push("Health: " + Math.round(batteryWidget.battery.healthPercentage) + "%");
            }
            return lines.join("\n");
        }
        tooltipVisible: false
        targetItem: batteryIcon
        delay: 200
    }
}
