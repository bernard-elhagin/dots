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
    property var updates: ({})
    property var pomodoro: ({ running: false, text: "POMO" })
    property string pomodoroCommand: homeDirectory + "/.local/bin/pomodoro"

    function isoWeek(date) {
        const day = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()))
        day.setUTCDate(day.getUTCDate() + 4 - (day.getUTCDay() || 7))
        const yearStart = new Date(Date.UTC(day.getUTCFullYear(), 0, 1))
        return Math.ceil(((day - yearStart) / 86400000 + 1) / 7)
    }

    Process {
        id: pomodoroReader
        command: [shell.pomodoroCommand, "--status"]
        stdout: SplitParser {
            onRead: data => {
                try { shell.pomodoro = JSON.parse(data) }
                catch (error) { shell.pomodoro = { running: false, text: "POMO" } }
            }
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: true
        onTriggered: { if (!pomodoroReader.running) pomodoroReader.running = true }
        Component.onCompleted: pomodoroReader.running = true
    }

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
                    shell.updates = JSON.parse(data)
                    shell.updateLabel = shell.updates.text || ""
                } catch (error) {
                    shell.updateLabel = ""
                }
            }
        }
    }

    Process {
        id: updateTerminal
        // A separate terminal process lets us refresh when the updater's window closes.
        command: ["xfce4-terminal", "--disable-server", "--title=System Update", "-x", "cachy-update"]
        onExited: { if (!updateReader.running) updateReader.running = true }
    }

    Timer {
        interval: 3000
        repeat: true
        running: true
        onTriggered: statusReader.exec(["bash", Quickshell.shellDir + "/taskbar-status.sh"])
        Component.onCompleted: statusReader.running = true
    }

    Timer {
        interval: 60000
        repeat: true
        running: true
        onTriggered: { if (!updateReader.running) updateReader.running = true }
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

            implicitHeight: 48
            exclusiveZone: 48
            color: "transparent"

            Rectangle {
                anchors.fill: parent
                anchors.margins: 2
                radius: 9
                gradient: Gradient {
                    GradientStop { position: 0; color: "#182037" }
                    GradientStop { position: 1; color: "#100F20" }
                }
                border.width: 1
                border.color: "#244854"

                // Thin luminous rails, with a quieter lower edge.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 1
                    color: "#183A48"
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: parent.width - 28
                    height: 1
                    opacity: 0.8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#183A48" }
                        GradientStop { position: 0.35; color: "#00E5FF" }
                        GradientStop { position: 0.65; color: "#B58CFF" }
                        GradientStop { position: 1; color: "#FF79B0" }
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 8

                    // Navigation deck.
                    Rectangle {
                        implicitHeight: 30
                        implicitWidth: osLabel.implicitWidth + 20
                        radius: 5
                        border.width: 1
                        border.color: osArea.containsMouse ? "#00E5FF" : "#28515E"
                        color: osArea.containsMouse ? "#163A46" : "#0D202B"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: osLabel
                            anchors.centerIn: parent
                            text: "◈ MAELLE"
                            color: osArea.containsMouse ? "#E1FBFF" : "#00E5FF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            font.letterSpacing: 1.5
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
                        color: "#00616E"
                    }

                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: 9

                            delegate: Rectangle {
                                required property int modelData
                                readonly property color accent: ["#00E5FF", "#82AAFF", "#B58CFF", "#FF79B0", "#FFAD80", "#F4D58D", "#85E6B4", "#79DBEA", "#C8A7FF"][modelData]
                                readonly property string expeditionName: ["Maelle", "Gustave", "Lune", "Sciel", "Verso", "Monoco", "Esquie", "Noco", "Gestral"][modelData]
                                id: workspaceButton
                                property bool tooltipReady: false
                                Timer {
                                    interval: 400
                                    running: workspaceArea.containsMouse && !workspaceArea.pressed
                                    onTriggered: workspaceButton.tooltipReady = true
                                }
                                PopupWindow {
                                    visible: workspaceArea.containsMouse && !workspaceArea.pressed
                                        && workspaceButton.tooltipReady
                                    implicitWidth: workspaceTooltipLabel.implicitWidth + 24
                                    implicitHeight: workspaceTooltipLabel.implicitHeight + 20
                                    color: "transparent"
                                    grabFocus: false
                                    // Labels must never intercept clicks on the workspace buttons.
                                    mask: Region {}
                                    anchor.item: workspaceButton
                                    anchor.edges: Edges.Bottom | Edges.Left
                                    anchor.gravity: Edges.Bottom | Edges.Right
                                    anchor.margins.top: 8
                                    Rectangle {
                                        anchors.fill: parent
                                        radius: 6
                                        color: "#100F20"
                                        border.width: 1
                                        border.color: "#695687"
                                        Text {
                                            id: workspaceTooltipLabel
                                            anchors.centerIn: parent
                                            text: "Expedition " + String(workspaceButton.modelData + 1).padStart(2, "0")
                                                + " · " + workspaceButton.expeditionName
                                            color: "#D7DEFF"
                                            font.family: "JetBrains Mono"
                                            font.pixelSize: 12
                                        }
                                    }
                                }
                                readonly property bool selected: Hyprland.focusedWorkspace
                                    ? Hyprland.focusedWorkspace.id === modelData + 1 : false
                                readonly property bool recentlyChanged: barWindow.lastChangedWorkspace === modelData + 1

                                width: 30
                                height: 28
                                radius: 5
                                color: selected ? Qt.rgba(accent.r, accent.g, accent.b, 0.20) : workspaceArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.10) : "#0C1721"
                                border.width: 1
                                border.color: selected || workspaceArea.containsMouse ? accent : Qt.rgba(accent.r, accent.g, accent.b, 0.32)
                                Behavior on color { ColorAnimation { duration: 140 } }
                                Behavior on border.color { ColorAnimation { duration: 160 } }

                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.bottomMargin: 3
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: parent.selected ? 12 : 3
                                    height: 2
                                    radius: 1
                                    color: parent.accent
                                    Behavior on width { NumberAnimation { duration: 180 } }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    text: String(modelData + 1).padStart(2, "0")
                                    color: parent.selected ? "#F2F6FF" : parent.accent
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 13
                                    font.bold: parent.selected
                                }

                                MouseArea {
                                    id: workspaceArea
                                    onExited: workspaceButton.tooltipReady = false
                                    onPressed: workspaceButton.tooltipReady = false
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
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
                        color: "#00616E"
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: ""
                            color: "#FFAD80"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["firefox"]) }
                        }
                        Text {
                            text: ""
                            color: "#82AAFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal", "-e", "yazi"]) }
                        }
                        Text {
                            text: ""
                            color: "#85E6B4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal"]) }
                        }
                        Text {
                            text: ""
                            color: "#B58CFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal", "-e", "nvim"]) }
                        }
                    }

                    Text {
                        Layout.maximumWidth: 170
                        Layout.minimumWidth: 40
                        elide: Text.ElideMiddle
                        text: "› " + (Hyprland.activeToplevel?.title || "SYSTEM READY")
                        color: "#85B8C8"
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
                                color: "#C8A7FF"
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

                    Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }

                    Text {
                        Layout.minimumWidth: 330
                        Layout.preferredWidth: 330
                        Layout.maximumWidth: 330
                        horizontalAlignment: Text.AlignHCenter
                        elide: Text.ElideRight
                        text: "Captain's Log - Stardate: " + Math.floor(clock.now.getTime() / 1000)
                        color: "#C8A7FF"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true; Layout.minimumWidth: 0 }

                    RowLayout {
                        spacing: 8

                        RowLayout {
                            spacing: 3
                            Repeater {
                                model: SystemTray.items
                                delegate: Item {
                                    id: trayIcon
                                    required property var modelData
                                    readonly property bool isNetwork: /nm-applet|networkmanager|network manager|networking/i.test(
                                        [modelData.id, modelData.title, modelData.tooltipTitle].join(" ")
                                    )
                                    readonly property bool isFlameshot: /flameshot/i.test(
                                        [modelData.id, modelData.title, modelData.tooltipTitle].join(" ")
                                    )
                                    visible: !/(steam|double.?commander|doublecmd|discord|vesktop)/i.test(
                                        [modelData.id, modelData.title, modelData.tooltipTitle, modelData.tooltipDescription].join(" ")
                                    )
                                    width: isNetwork ? 22 : 16
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
                                        visible: !trayIcon.isNetwork
                                        colorization: 0.0
                                        colorizationColor: "#00E5FF"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: trayIcon.isNetwork
                                        text: shell.stats.network === "ETH" ? "󰈀"
                                            : shell.stats.network && shell.stats.network !== "OFF" ? "󰤨" : "󰤭"
                                        color: shell.stats.network && shell.stats.network !== "OFF" ? "#00E5FF" : "#747895"
                                        font.family: "JetBrains Mono"
                                        font.pixelSize: 18
                                    }

                                    MouseArea {
                                        id: trayIconArea
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton | Qt.RightButton
                                        onClicked: mouse => {
                                            if (modelData.hasMenu && (mouse.button === Qt.RightButton || modelData.onlyMenu)) {
                                                if (trayIcon.isNetwork || trayIcon.isFlameshot) {
                                                    const alreadyOpen = networkTrayMenu.visible
                                                        && networkTrayMenu.menuHandle === modelData.menu
                                                    networkTrayMenu.visible = false
                                                    networkTrayMenu.anchor.item = trayIcon
                                                    networkTrayMenu.menuHandle = modelData.menu
                                                    networkTrayMenu.menuTitle = trayIcon.isFlameshot ? "FLAMESHOT" : "NETWORK"
                                                    networkTrayMenu.visible = !alreadyOpen
                                                } else {
                                                    const point = trayIcon.mapToItem(barWindow.contentItem, 0, 0)
                                                    modelData.display(barWindow, Math.round(point.x), Math.round(point.y + trayIcon.height))
                                                }
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
                            id: updateWidget
                            property bool hoverReady: false
                            Timer {
                                interval: 500
                                running: updateArea.containsMouse
                                onTriggered: updateWidget.hoverReady = true
                            }
                            visible: shell.updateLabel !== ""
                            text: shell.updateLabel
                            color: "#66EFFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 16
                            MouseArea {
                                id: updateArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onExited: updateWidget.hoverReady = false
                                onClicked: { if (!updateTerminal.running) updateTerminal.running = true }
                            }
                        }

                        IdleInhibitor {
                            id: idleInhibitor
                            window: barWindow
                        }
                        Text {
                            text: idleInhibitor.enabled ? "󰅶" : "󰾪"
                            color: idleInhibitor.enabled ? "#F4D58D" : "#747895"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: idleInhibitor.enabled = !idleInhibitor.enabled }
                        }

                        Text {
                            readonly property var sink: Pipewire.defaultAudioSink
                            text: !sink || !sink.ready || !sink.audio ? "󰖁" : sink.audio.muted ? "󰖁" : "󰕾 " + Math.round(sink.audio.volume * 100)
                            color: "#F4D58D"
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
                            color: shell.stats.bluetooth === "on" ? "#82AAFF" : "#495571"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                        }

                        Text {
                            visible: shell.stats.vpn === "on"
                            text: ""
                            color: "#B58CFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", shell.homeDirectory + "/.config/waybar/scripts/vpnmenu.sh"]) }
                        }

                        Text {
                            text: "󰘚 " + (shell.stats.memory || "--") + "%"
                            color: "#B58CFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: "󰍛 " + shell.cpuUsage + "%"
                            color: "#82AAFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: " " + (shell.stats.temperature || "--")
                            color: "#FFAD80"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: shell.stats.brightness !== ""
                            text: "󰖙 " + (shell.stats.brightness || "")
                            color: "#F4D58D"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                            text: "󰁹 " + Math.round(UPower.displayDevice.percentage) + "%"
                            color: "#85E6B4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                    }

                    Rectangle {
                        id: pomodoroWidget
                        property bool hoverReady: false
                        Timer {
                            interval: 350
                            running: pomodoroArea.containsMouse
                            onTriggered: pomodoroWidget.hoverReady = true
                        }
                        implicitWidth: pomodoroLabel.implicitWidth + 18
                        height: 28
                        radius: 5
                        color: pomodoroArea.containsMouse ? "#173342" : "#101E2B"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        border.width: 1
                        border.color: shell.pomodoro.running ? "#00E5FF" : "#00616E"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            height: 2
                            radius: 1
                            color: "#293344"
                            visible: shell.pomodoro.running && Number(shell.pomodoro.duration) > 0
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1,
                                    1 - Number(shell.pomodoro.remaining) / Number(shell.pomodoro.duration)))
                                height: parent.height
                                radius: 1
                                color: shell.pomodoro.phase === "work" ? "#B58CFF" : "#85E6B4"
                                Behavior on width { NumberAnimation { duration: 300 } }
                            }
                        }

                        Text {
                            id: pomodoroLabel
                            anchors.centerIn: parent
                            text: !shell.pomodoro.running ? "◷ GRADIENT"
                                : (shell.pomodoro.paused ? "Ⅱ " : "◷ ")
                                  + (shell.pomodoro.phase === "work" ? "CHARGE " : "REST ")
                                  + shell.pomodoro.text
                            color: !shell.pomodoro.running ? "#00B4C8"
                                : shell.pomodoro.paused ? "#66EFFF"
                                : shell.pomodoro.phase === "work" ? "#FF7887" : "#A6D189"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        MouseArea {
                            id: pomodoroArea
                            onExited: pomodoroWidget.hoverReady = false
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (shell.pomodoro.running)
                                    Quickshell.execDetached([shell.pomodoroCommand, "--toggle"])
                                else
                                    Quickshell.execDetached(["xfce4-terminal", "--title=Pomodoro", "-x", shell.pomodoroCommand])
                            }
                        }
                    }

                    Text {
                        id: dateLabel
                        property bool copied: false
                        text: Qt.formatDateTime(clock.now, "ddd dd MMM | HH:mm:ss")
                        color: "#D7DEFF"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 15
                        property bool hoverReady: false
                        Timer {
                            interval: 350
                            running: dateArea.containsMouse && !almanac.visible
                            onTriggered: dateLabel.hoverReady = true
                        }
                        Timer { id: copyReset; interval: 2000; onTriggered: dateLabel.copied = false }
                        MouseArea {
                            id: dateArea
                            anchors.fill: parent
                            onExited: dateLabel.hoverReady = false
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                if (mouse.button === Qt.RightButton) {
                                    Quickshell.execDetached(["wl-copy", "--", Qt.formatDateTime(clock.now, "yyyy-MM-dd HH:mm:ss t")])
                                    dateLabel.copied = true
                                    copyReset.restart()
                                } else {
                                    almanac.visible = !almanac.visible
                                }
                            }
                        }
                    }


                }


            }

            TrayMenu {
                id: networkTrayMenu
                visible: false
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.margins.top: 8
            }

            PopupWindow {
                id: updatesTooltip
                visible: updateWidget.visible && updateArea.containsMouse && updateWidget.hoverReady
                implicitWidth: 350
                implicitHeight: updatesTooltipContent.implicitHeight + 32
                color: "transparent"
                grabFocus: false
                anchor.item: updateWidget
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.margins.top: 8
                Rectangle {
                    anchors.fill: parent
                    color: "#100F20"
                    radius: 10
                    border.width: 1
                    border.color: "#695687"
                    Column {
                        id: updatesTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "AVAILABLE UPDATES"
                            color: "#00E5FF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: "Pacman: " + Number(shell.updates.repo || 0)
                                + "\nAUR: " + Number(shell.updates.aur || 0)
                                + "\nFlatpak: " + Number(shell.updates.flatpak || 0)
                            color: "#D7DEFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Total: " + (Number(shell.updates.repo || 0)
                                + Number(shell.updates.aur || 0) + Number(shell.updates.flatpak || 0))
                            color: "#85E6B4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Click to run cachy-update"
                            color: "#85B8C8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            PopupWindow {
                id: pomodoroTooltip
                visible: pomodoroArea.containsMouse && pomodoroWidget.hoverReady
                implicitWidth: 350
                implicitHeight: pomodoroTooltipContent.implicitHeight + 32
                color: "transparent"
                grabFocus: false
                anchor.item: pomodoroWidget
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.margins.top: 8
                Rectangle {
                    anchors.fill: parent
                    color: "#100F20"
                    radius: 10
                    border.width: 1
                    border.color: "#695687"
                    Column {
                        id: pomodoroTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "GRADIENT CHARGE"
                            color: "#00E5FF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: !shell.pomodoro.running ? "Ready for a focus session"
                                : (shell.pomodoro.phase === "work" ? "Focus" : "Rest")
                                  + (shell.pomodoro.paused ? " · Paused" : " · In progress")
                                  + " · " + shell.pomodoro.text
                            color: "#D7DEFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Expeditions completed today: " + Number(shell.pomodoro.completedToday || 0)
                            color: "#85E6B4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: shell.pomodoro.running
                                ? "Click to pause/resume\nKeep its terminal open"
                                : "Click to start Pomodoro"
                            color: "#85B8C8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            PopupWindow {
                id: clockTooltip
                visible: dateArea.containsMouse && dateLabel.hoverReady && !almanac.visible
                implicitWidth: 350
                implicitHeight: clockTooltipContent.implicitHeight + 32
                color: "transparent"
                grabFocus: false
                anchor.item: dateLabel
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.margins.top: 8
                Rectangle {
                    anchors.fill: parent
                    color: "#100F20"
                    radius: 10
                    border.width: 1
                    border.color: "#695687"
                    Column {
                        id: clockTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "LUMIÈRE ALMANAC"
                            color: "#00E5FF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: dateLabel.copied ? "Date and time copied"
                                : Qt.formatDateTime(clock.now, "dddd, d MMMM yyyy")
                            color: dateLabel.copied ? "#85E6B4" : "#D7DEFF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "ISO week " + shell.isoWeek(clock.now)
                                + " · " + Qt.formatDateTime(clock.now, "tttt (t)")
                            color: "#D2B8FF"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Expeditions completed today: " + Number(shell.pomodoro.completedToday || 0)
                            color: "#85E6B4"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Click to open calendar\nRight-click to copy date and time"
                            color: "#85B8C8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 11
                        }
                    }
                }
            }

            Almanac {
                id: almanac
                visible: false
                now: clock.now
                completedToday: Number(shell.pomodoro.completedToday || 0)
                anchorHovered: dateArea.containsMouse
                anchor.item: dateLabel
                anchor.edges: Edges.Bottom | Edges.Right
                anchor.gravity: Edges.Bottom | Edges.Left
                anchor.margins.top: 8
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
