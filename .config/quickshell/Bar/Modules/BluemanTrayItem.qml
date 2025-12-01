import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import QtQuick.Effects
import Quickshell.Services.SystemTray
import Quickshell.Widgets
import qs.Settings
import qs.Components

Item {
    id: root
    property var bar
    property var trayMenu

    // Find the Blueman tray item
    property var bluemanItem: {
        if (!SystemTray.items) return null;

        for (let i = 0; i < SystemTray.items.count; i++) {
            let item = SystemTray.items.valueAt(i);
            // Match blueman by id, name, or tooltip
            if (item && (
                (item.id && item.id.toLowerCase().includes("blueman")) ||
                (item.name && item.name.toLowerCase().includes("blueman")) ||
                (item.tooltipTitle && item.tooltipTitle.toLowerCase().includes("bluetooth"))
            )) {
                return item;
            }
        }
        return null;
    }

    width: bluemanItem ? 24 * Theme.scale(Screen) : 0
    height: bluemanItem ? 24 * Theme.scale(Screen) : 0
    visible: bluemanItem !== null

    Item {
        width: 24 * Theme.scale(Screen)
        height: 24 * Theme.scale(Screen)
        visible: bluemanItem !== null

        property bool isHovered: trayMouseArea.containsMouse

        Rectangle {
            anchors.centerIn: parent
            width: 16 * Theme.scale(Screen)
            height: 16 * Theme.scale(Screen)
            radius: 6
            color: "transparent"
            clip: true

            IconImage {
                id: trayIcon
                anchors.centerIn: parent
                width: 16 * Theme.scale(Screen)
                height: 16 * Theme.scale(Screen)
                smooth: false
                asynchronous: true
                backer.fillMode: Image.PreserveAspectFit
                source: {
                    if (!bluemanItem || !bluemanItem.icon) return "";
                    let icon = bluemanItem.icon;

                    // Process icon path
                    if (icon.includes("?path=")) {
                        const [name, path] = icon.split("?path=");
                        const fileName = name.substring(name.lastIndexOf("/") + 1);
                        return `file://${path}/${fileName}`;
                    }
                    return icon;
                }
                opacity: status === Image.Ready ? 1 : 0
            }
        }

        MouseArea {
            id: trayMouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
            onClicked: mouse => {
                if (!bluemanItem) return;

                if (mouse.button === Qt.LeftButton) {
                    // Close any open menu first
                    if (trayMenu && trayMenu.visible) {
                        trayMenu.hideMenu();
                    }

                    if (!bluemanItem.onlyMenu) {
                        bluemanItem.activate();
                    }
                } else if (mouse.button === Qt.MiddleButton) {
                    // Close any open menu first
                    if (trayMenu && trayMenu.visible) {
                        trayMenu.hideMenu();
                    }

                    bluemanItem.secondaryActivate && bluemanItem.secondaryActivate();
                } else if (mouse.button === Qt.RightButton) {
                    trayTooltip.tooltipVisible = false;
                    // If menu is already visible, close it
                    if (trayMenu && trayMenu.visible) {
                        trayMenu.hideMenu();
                        return;
                    }

                    if (bluemanItem.hasMenu && bluemanItem.menu && trayMenu) {
                        // Anchor the menu to the tray icon item and position it below
                        const menuX = (width / 2) - (trayMenu.width / 2);
                        const menuY = height + 20 * Theme.scale(Screen);
                        trayMenu.menu = bluemanItem.menu;
                        trayMenu.showAt(parent, menuX, menuY);
                    }
                }
            }
            onEntered: trayTooltip.tooltipVisible = true
            onExited: trayTooltip.tooltipVisible = false
        }

        StyledTooltip {
            id: trayTooltip
            text: bluemanItem ? (bluemanItem.tooltipTitle || bluemanItem.name || bluemanItem.id || "Bluetooth Manager") : ""
            positionAbove: false
            tooltipVisible: false
            targetItem: trayIcon
            delay: 200
        }
    }
}
