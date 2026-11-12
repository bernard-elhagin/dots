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
                    GradientStop { position: 0; color: "#1C2639" }
                    GradientStop { position: 1; color: "#111827" }
                }
                border.width: 1
                border.color: "#3D4C68"

                // Thin luminous rails, with a quieter lower edge.
                Rectangle {
                    anchors.bottom: parent.bottom
                    anchors.horizontalCenter: parent.horizontalCenter
                    width: parent.width - 24
                    height: 1
                    color: "#30405E"
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.top: parent.top
                    width: parent.width - 28
                    height: 1
                    opacity: 0.8
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0; color: "#30405E" }
                        GradientStop { position: 0.35; color: "#A5B4FC" }
                        GradientStop { position: 0.65; color: "#E7D39B" }
                        GradientStop { position: 1; color: "#CFBF91" }
                    }
                }

                RowLayout {
                    id: barContent
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
                        border.color: osArea.containsMouse ? "#A5B4FC" : "#3D4C68"
                        color: osArea.containsMouse ? "#2C3B59" : "#182337"
                        Behavior on color { ColorAnimation { duration: 140 } }

                        Text {
                            id: osLabel
                            anchors.centerIn: parent
                            text: "◈ MAELLE"
                            color: osArea.containsMouse ? "#F2F4FF" : "#A5B4FC"
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
                        color: "#53678C"
                    }

                    RowLayout {
                        spacing: 4

                        Repeater {
                            model: 9

                            delegate: Rectangle {
                                required property int modelData
                                readonly property color accent: ["#A5B4FC", "#A4BBD8", "#E7D39B", "#CFBF91", "#D8C7A6", "#E7D39B", "#A6CECA", "#A7C0DB", "#B8B8DE"][modelData]
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
                                        color: "#111827"
                                        border.width: 1
                                        border.color: "#3D4C68"
                                        Text {
                                            id: workspaceTooltipLabel
                                            anchors.centerIn: parent
                                            text: "Expedition " + String(workspaceButton.modelData + 1).padStart(2, "0")
                                                + " · " + workspaceButton.expeditionName
                                            color: "#E8EDF7"
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
                                color: selected ? Qt.rgba(accent.r, accent.g, accent.b, 0.20) : workspaceArea.containsMouse ? Qt.rgba(accent.r, accent.g, accent.b, 0.10) : "#151F31"
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
                                    color: parent.selected ? "#F5F7FF" : parent.accent
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
                        color: "#53678C"
                    }

                    RowLayout {
                        spacing: 8

                        Text {
                            text: ""
                            color: "#D8C7A6"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["firefox"]) }
                        }
                        Text {
                            text: ""
                            color: "#A4BBD8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal", "-e", "yazi"]) }
                        }
                        Text {
                            text: ""
                            color: "#A6CECA"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 19
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["xfce4-terminal"]) }
                        }
                        Text {
                            text: ""
                            color: "#E7D39B"
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
                        color: "#A5B2C9"
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
                                color: "#B8B8DE"
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

                    // One flexible gap; the log itself is anchored to the bar centre.
                    Item {
                        id: captainSpace
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                    }

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
                                        colorizationColor: "#A5B4FC"
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: trayIcon.isNetwork
                                        text: shell.stats.network === "ETH" ? "󰈀"
                                            : shell.stats.network && shell.stats.network !== "OFF" ? "󰤨" : "󰤭"
                                        color: shell.stats.network && shell.stats.network !== "OFF" ? "#A5B4FC" : "#A5B2C9"
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
                            color: "#CDD6FF"
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
                            color: idleInhibitor.enabled ? "#E7D39B" : "#A5B2C9"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: idleInhibitor.enabled = !idleInhibitor.enabled }
                        }

                        Text {
                            readonly property var sink: Pipewire.defaultAudioSink
                            text: !sink || !sink.ready || !sink.audio ? "󰖁" : sink.audio.muted ? "󰖁" : "󰕾 " + Math.round(sink.audio.volume * 100)
                            color: "#E7D39B"
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
                            color: shell.stats.bluetooth === "on" ? "#A4BBD8" : "#71809A"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 18
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["blueman-manager"]) }
                        }

                        Text {
                            visible: shell.stats.vpn === "on"
                            text: ""
                            color: "#E7D39B"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 17
                            MouseArea { anchors.fill: parent; onClicked: Quickshell.execDetached(["bash", shell.homeDirectory + "/.config/waybar/scripts/vpnmenu.sh"]) }
                        }

                        Text {
                            text: "󰘚 " + (shell.stats.memory || "--") + "%"
                            color: "#E7D39B"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: "󰍛 " + shell.cpuUsage + "%"
                            color: "#A4BBD8"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            text: " " + (shell.stats.temperature || "--")
                            color: "#D8C7A6"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: shell.stats.brightness !== ""
                            text: "󰖙 " + (shell.stats.brightness || "")
                            color: "#E7D39B"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 14
                        }
                        Text {
                            visible: UPower.displayDevice.ready && UPower.displayDevice.isLaptopBattery
                            text: "󰁹 " + Math.round(UPower.displayDevice.percentage) + "%"
                            color: "#A6CECA"
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
                        color: pomodoroArea.containsMouse ? "#293655" : "#1C2639"
                        Behavior on color { ColorAnimation { duration: 140 } }
                        border.width: 1
                        border.color: shell.pomodoro.running ? "#A5B4FC" : "#53678C"

                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.margins: 4
                            height: 2
                            radius: 1
                            color: "#34415A"
                            visible: shell.pomodoro.running && Number(shell.pomodoro.duration) > 0
                            Rectangle {
                                width: parent.width * Math.max(0, Math.min(1,
                                    1 - Number(shell.pomodoro.remaining) / Number(shell.pomodoro.duration)))
                                height: parent.height
                                radius: 1
                                color: shell.pomodoro.phase === "work" ? "#E7D39B" : "#A6CECA"
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
                            color: !shell.pomodoro.running ? "#879BCB"
                                : shell.pomodoro.paused ? "#CDD6FF"
                                : shell.pomodoro.phase === "work" ? "#EF8F9C" : "#ACD2B5"
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
                        color: "#E7D39B"
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

                Text {
                    anchors.centerIn: parent
                    // Shrink symmetrically if side widgets reach the centre.
                    // This preserves the centre position and avoids drawing over controls.
                    width: Math.max(0, Math.min(330,
                        parent.width - 2 * (barContent.x + captainSpace.x),
                        2 * (barContent.x + captainSpace.x + captainSpace.width) - parent.width))
                    visible: width > 0
                    horizontalAlignment: Text.AlignHCenter
                    elide: Text.ElideRight
                    text: "Captain's Log - Stardate: " + Math.floor(clock.now.getTime() / 1000)
                    color: "#B8B8DE"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 13
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
                    color: "#111827"
                    radius: 10
                    border.width: 1
                    border.color: "#3D4C68"
                    Column {
                        id: updatesTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "AVAILABLE UPDATES"
                            color: "#A5B4FC"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            text: "Pacman: " + Number(shell.updates.repo || 0)
                                + "\nAUR: " + Number(shell.updates.aur || 0)
                                + "\nFlatpak: " + Number(shell.updates.flatpak || 0)
                            color: "#E8EDF7"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            text: "Total: " + (Number(shell.updates.repo || 0)
                                + Number(shell.updates.aur || 0) + Number(shell.updates.flatpak || 0))
                            color: "#A6CECA"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            text: "Click to run cachy-update"
                            color: "#A5B2C9"
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
                    color: "#111827"
                    radius: 10
                    border.width: 1
                    border.color: "#3D4C68"
                    Column {
                        id: pomodoroTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "GRADIENT CHARGE"
                            color: "#A5B4FC"
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
                            color: "#E8EDF7"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Expeditions completed today: " + Number(shell.pomodoro.completedToday || 0)
                            color: "#A6CECA"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: shell.pomodoro.running
                                ? "Click to pause/resume\nKeep its terminal open"
                                : "Click to start Pomodoro"
                            color: "#A5B2C9"
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
                    color: "#111827"
                    radius: 10
                    border.width: 1
                    border.color: "#3D4C68"
                    Column {
                        id: clockTooltipContent
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.margins: 16
                        spacing: 8
                        Text {
                            text: "LUMIÈRE ALMANAC"
                            color: "#A5B4FC"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 15
                            font.bold: true
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: dateLabel.copied ? "Date and time copied"
                                : Qt.formatDateTime(clock.now, "dddd, d MMMM yyyy")
                            color: dateLabel.copied ? "#A6CECA" : "#E8EDF7"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "ISO week " + shell.isoWeek(clock.now)
                                + " · " + Qt.formatDateTime(clock.now, "tttt (t)")
                            color: "#D8D6EE"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Expeditions completed today: " + Number(shell.pomodoro.completedToday || 0)
                            color: "#A6CECA"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 12
                        }
                        Text {
                            width: parent.width
                            wrapMode: Text.WordWrap
                            text: "Click to open calendar\nRight-click to copy date and time"
                            color: "#A5B2C9"
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
