import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: popup
    property var menuHandle: null
    property string menuTitle: "NETWORK"
    property var trail: []
    readonly property var currentMenu: trail.length ? trail[trail.length - 1] : menuHandle
    implicitWidth: 350
    implicitHeight: menuLayout.implicitHeight + 32
    color: "transparent"
    grabFocus: true
    onVisibleChanged: { if (!visible) trail = [] }

    // Keep the root open while navigating its dynamically exported children.
    QsMenuOpener { id: rootMenu; menu: popup.visible ? popup.menuHandle : null }
    QsMenuOpener { id: submenu; menu: popup.visible && popup.trail.length ? popup.currentMenu : null }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#101D21"
        border.width: 1
        border.color: "#36565C"
        focus: true
        Keys.onEscapePressed: popup.visible = false
        ColumnLayout {
            id: menuLayout
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 16
            spacing: 10
            RowLayout {
                Text {
                    text: popup.trail.length ? "‹" : "◈"
                    color: "#DCC998"
                    font.pixelSize: 18
                    MouseArea {
                        anchors.fill: parent
                        enabled: popup.trail.length > 0
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.trail = popup.trail.slice(0, -1)
                    }
                }
                Text {
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    text: popup.trail.length ? popup.currentMenu.text.replace(/&([^&])/g, "$1") : popup.menuTitle
                    color: "#73DACA"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 15
                    font.bold: true
                }
                Text {
                    text: "×"
                    color: "#DCC998"
                    font.pixelSize: 20
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: popup.visible = false
                    }
                }
            }
            Flickable {
                Layout.fillWidth: true
                implicitHeight: Math.min(entries.implicitHeight, 420)
                contentHeight: entries.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                Column {
                    id: entries
                    width: parent.width
                    spacing: 4
                    Repeater {
                        model: popup.trail.length ? submenu.children : rootMenu.children
                        Rectangle {
                            id: row
                            required property var modelData
                            width: entries.width
                            height: modelData.isSeparator ? 9 : 34
                            radius: 4
                            color: !modelData.isSeparator && rowArea.containsMouse && modelData.enabled ? "#284448" : "transparent"
                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: parent.width
                                height: 1
                                color: "#30474A"
                                visible: row.modelData.isSeparator
                            }
                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                visible: !row.modelData.isSeparator
                                spacing: 8
                                Text {
                                    text: row.modelData.checkState === Qt.Checked ? "✓" : ""
                                    Layout.preferredWidth: 12
                                    color: "#9DC6A5"
                                    font.pixelSize: 13
                                }
                                Text {
                                    Layout.fillWidth: true
                                    text: row.modelData.text.replace(/&([^&])/g, "$1")
                                    elide: Text.ElideRight
                                    color: !row.modelData.enabled ? "#91A7A0" : rowArea.containsMouse ? "#DCC998" : "#E8E6DD"
                                    font.family: "JetBrains Mono"
                                    font.pixelSize: 12
                                }
                                Text {
                                    text: row.modelData.hasChildren ? "›" : ""
                                    color: "#E9C46A"
                                    font.pixelSize: 18
                                }
                            }
                            MouseArea {
                                id: rowArea
                                anchors.fill: parent
                                enabled: row.modelData.enabled && !row.modelData.isSeparator
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (row.modelData.hasChildren) {
                                        popup.trail = popup.trail.concat([row.modelData])
                                    } else {
                                        row.modelData.triggered()
                                        popup.visible = false
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
