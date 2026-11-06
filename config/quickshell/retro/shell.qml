//@ pragma UseQApplication

import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import QtQuick.Layouts
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire
import Quickshell.Services.SystemTray
import Quickshell.Services.UPower
import Quickshell.Wayland

ShellRoot {
    id: shell

    property string homeDirectory: Quickshell.env("HOME") || "/home/bertold"
    property var stats: ({})
    property int previousCpuTotal: 0
    property int previousCpuIdle: 0
    property int cpuUsage: 0
    property string updateLabel: ""

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }

    Process {
        id: statusReader
        command: ["bash", Quickshell.shellDir + "/taskbar-status.sh"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    const next = JSON.parse(data)
                    if (shell.previousCpuTotal > 0 && next.cpuTotal > shell.previousCpuTotal) {
                        const total = next.cpuTotal - shell.previousCpuTotal
                        const idle = next.cpuIdle - shell.previousCpuIdle
                        shell.cpuUsage = Math.max(0, Math.min(100, Math.round(100 * (total - idle) / total)))
                    }
                    shell.previousCpuTotal = next.cpuTotal
                    shell.previousCpuIdle = next.cpuIdle
                    shell.stats = next
                } catch (error) {
                    console.warn("Could not read taskbar status:", error)
                }
            }
        }
    }

    Process {
        id: updateReader
        command: ["bash", Quickshell.shellDir + "/taskbar-status.sh", "updates"]
        stdout: SplitParser {
            onRead: data => {
                try {
                    shell.updateLabel = JSON.parse(data).text || ""
                } catch (error) {
                    shell.updateLabel = ""
                }
            }
        }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: statusReader.exec(["bash", Quickshell.shellDir + "/taskbar-status.sh"])
        Component.onCompleted: statusReader.running = true
    }

    Timer {
        interval: 600000
        repeat: true
        running: true
        onTriggered: updateReader.exec(["bash", Quickshell.shellDir + "/taskbar-status.sh", "updates"])
        Component.onCompleted: updateReader.running = true
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: barWindow
            required property var modelData
            property int lastChangedWorkspace: -1
            screen: modelData

            Connections {
                target: Hyprland
                function onFocusedWorkspaceChanged() {
                    if (Hyprland.focusedWorkspace)
                        barWindow.lastChangedWorkspace = Hyprland.focusedWorkspace.id
                }
            }

            anchors {
                top: true
                left: true
                right: true
            }

            implicitHeight: 42
            exclusiveZone: 42
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                color: "#11100D"
                border.width: 1
                border.color: "#6E4A00"

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: 2
                    color: "#FFB000"
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    // System menu and workspace controls keep the original amber terminal style.
                    Rectangle {
                        Layout.fillHeight: true
                        implicitWidth: osLabel.implicitWidth + 12
                        color: osArea.containsMouse ? "#FFB000" : "transparent"

                        Text {
                            id: osLabel
                            anchors.centerIn: parent
                            text: "AMBER_OS"
                            color: osArea.containsMouse ? "#11100D" : "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                            font.bold: true
                        }

                        MouseArea {
                            id: osArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["bash", shell.homeDirectory + "/.config/waybar/scripts/system.sh"])
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 9
                        Layout.bottomMargin: 9
                        color: "#6E4A00"
                    }

                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: 5

                            delegate: Rectangle {
                                required property int modelData
                                readonly property bool selected: Hyprland.focusedWorkspace
                                    ? Hyprland.focusedWorkspace.id === modelData + 1 : false
                                readonly property bool recentlyChanged: barWindow.lastChangedWorkspace === modelData + 1

                                width: 28
                                height: 25
                                color: recentlyChanged ? "#FFD24A" : selected ? "#FFB000" : "transparent"
                                border.width: recentlyChanged ? 2 : 1
                                border.color: recentlyChanged ? "#FFF0A3" : selected ? "#FFB000" : "#6E4A00"

                                Text {
                                    anchors.centerIn: parent
                                    text: String(modelData + 1).padStart(2, "0")
                                    color: parent.selected || parent.recentlyChanged ? "#11100D" : "#C88700"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 16
                                    font.bold: parent.selected || parent.recentlyChanged
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: {
                                        const workspace = modelData + 1
                                        if (Hyprland.focusedWorkspace?.id === workspace) {
                                            Hyprland.dispatch('hl.dsp.focus({ workspace = "previous" })')
                                        } else {
                                            Hyprland.dispatch(`hl.dsp.focus({ workspace = ${workspace} })`)
                                        }
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        width: 1
                        Layout.fillHeight: true
                        Layout.topMargin: 9
                        Layout.bottomMargin: 9
                        color: "#6E4A00"
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: ""
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["firefox"]) }
                        }
                        Text {
                            text: ""
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal", "-e", "yazi"]) }
                        }
                        Text {
                            text: ""
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal"]) }
                        }
                        Text {
                            text: ""
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal", "-e", "nvim"]) }
                        }
                    }

                    Text {
                        Layout.maximumWidth: 170
                        Layout.minimumWidth: 40
                        elide: Text.ElideMiddle
                        text: Hyprland.activeToplevel?.title || "DESKTOP"
                        color: "#C88700"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 14
                    }

                    RowLayout {
                        spacing: 5
                        visible: Mpris.players.count > 0

                        Repeater {
                            model: Mpris.players
                            delegate: Text {
                                required property var modelData
                                visible: modelData.isPlaying && modelData.trackTitle !== ""
                                text: "♫ " + modelData.trackTitle
                                color: "#A66F00"
                                font.family: "JetBrains Mono"
                                font.pixelSize: 15
                                elide: Text.ElideRight
                                width: 150
                                MouseArea {
                                    anchors.fill: parent
                                    onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                                }
                            }
                        }
                    }

                    Item { Layout.fillWidth: true; Layout.minimumWidth: 8 }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: "⏻"
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 20
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached([Quickshell.shellDir + "/power-menu.sh"]) }
                        }

                        RowLayout {
                            spacing: 3
                            Repeater {
                                model: SystemTray.items
                                delegate: Item {
                                    id: trayIcon
                                    required property var modelData
                                    visible: !/(steam|double.?commander|doublecmd)/i.test(
                                        [modelData.id, modelData.title, modelData.tooltipTitle, modelData.tooltipDescription].join(" ")
                                    )
                                    width: 16
                                    height: 18

                                    Image {
                                        id: trayIconSource
                                        anchors.fill: parent
                                        source: trayIcon.modelData.icon
                                        sourceSize.width: 16
                                        sourceSize.height: 16
                                        fillMode: Image.PreserveAspectFit
                                        visible: false
                                    }

                                    MultiEffect {
                                        anchors.fill: parent
                                        source: trayIconSource
                                        colorization: 1.0
                                        colorizationColor: "#FFB000"
                                    }

                                    MouseArea {
                                        id: trayIconArea
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (modelData.hasMenu && (mouse.button === Qt.RightButton || modelData.onlyMenu)) {
                                                const point = trayIcon.mapToItem(barWindow.contentItem, 0, 0)
                                                modelData.display(barWindow, Math.round(point.x), Math.round(point.y + trayIcon.height))
                                            } else if (mouse.button === Qt.LeftButton) {
                                                modelData.activate()
                                            }
                                        }
                                        ToolTip.visible: containsMouse
                                        ToolTip.delay: 500
                                        ToolTip.text: [modelData.tooltipTitle || modelData.title || modelData.id, modelData.tooltipDescription]
                                            .filter(value => value)
                                            .join("\n")
                                    }
                                }
                            }
                        }

                        Text {
                            visible: shell.updateLabel !== ""
                            text: shell.updateLabel
                            color: "#FFD24A"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                        }

                        IdleInhibitor {
                            id: idleInhibitor
                            window: barWindow
                        }
                        Text {
                            text: idleInhibitor.enabled ? "󰅶" : "󰾪"
                            color: idleInhibitor.enabled ? "#FFB000" : "#A66F00"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: idleInhibitor.enabled = !idleInhibitor.enabled }
                        }

                        Text {
                            readonly property var sink: Pipewire.defaultAudioSink
                            text: !sink || !sink.ready || !sink.audio ? "󰖁" : sink.audio.muted ? "󰖁" : "󰕾 " + Math.round(sink.audio.volume * 100)
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.MiddleButton)
                                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"])
                                    else
                                        Quickshell.execDetached(["pavucontrol"])
                                }
                                onWheel: wheel => Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", wheel.angleDelta.y > 0 ? "5%+" : "5%-"])
                            }
                        }

                        Text {
                            text: shell.stats.bluetooth === "on" ? "󰂱" : "󰂲"
                            color: shell.stats.bluetooth === "on" ? "#FFB000" : "#6E4A00"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                        }

                        Text {
                            text: shell.stats.network === "OFF"
                                ? "󰤮"
                                : shell.stats.network === "ETH"
                                    ? ""
                                    : "󰤨 " + (shell.stats.network || "NET")
                            color: shell.stats.network && shell.stats.network !== "OFF" ? "#FFB000" : "#A66F00"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                            width: 78
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", shell.homeDirectory + "/.config/waybar/scripts/networkmenu.sh"]) }
                        }

                        Text {
                            visible: shell.stats.vpn === "on"
                            text: ""
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", shell.homeDirectory + "/.config/waybar/scripts/vpnmenu.sh"]) }
                        }

                        Text {
                            text: "󰘚 " + (shell.stats.memory || "--") + "%"
                            color: "#C88700"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: "󰍛 " + shell.cpuUsage + "%"
                            color: "#C88700"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: " " + (shell.stats.temperature || "--")
                            color: "#C88700"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: shell.stats.brightness !== ""
                            text: "󰖙 " + (shell.stats.brightness || "")
                            color: "#A66F00"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                            text: "󰁹 " + Math.round(UPower.displayDevice.percentage) + "%"
                            color: "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                    }

                    Text {
                        text: Qt.formatDateTime(clock.now, "ddd dd MMM | HH:mm:ss")
                        color: "#FFB000"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                    }

                    Rectangle {
                        width: 58
                        height: 25
                        color: launcherArea.containsMouse ? "#FFB000" : "transparent"
                        border.width: 1
                        border.color: "#FFB000"
                        Text {
                            anchors.centerIn: parent
                            text: "RUN  >"
                            color: launcherArea.containsMouse ? "#11100D" : "#FFB000"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        MouseArea {
                            id: launcherArea
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: Quickshell.execDetached(["rofi", "-show", "drun"])
                        }
                    }
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(360, parent.width * 0.4)
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: "Captain's Log - Stardate: " + Math.floor(clock.now.getTime() / 1000)
                    color: "#A66F00"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                    z: 1
                }
            }

            QtObject {
                id: clock
                property date now: new Date()
            }

            Timer {
                interval: 1000
                repeat: true
                running: true
                onTriggered: clock.now = new Date()
            }
        }
    }
}
