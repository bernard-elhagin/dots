import QtQuick
import QtQuick.Layouts
import Quickshell

PopupWindow {
    id: almanac
    required property date now
    property int completedToday: 0
    property bool anchorHovered: false
    property date month: new Date(now.getFullYear(), now.getMonth(), 1)
    implicitWidth: 350
    implicitHeight: 370
    color: "transparent"
    grabFocus: true

    function today() {
        month = new Date(now.getFullYear(), now.getMonth(), 1)
    }
    function moveMonth(delta) {
        month = new Date(month.getFullYear(), month.getMonth() + delta, 1)
    }
    function cellDate(index) {
        const offset = (month.getDay() + 6) % 7
        return new Date(month.getFullYear(), month.getMonth(), 1 + index - offset)
    }
    onVisibleChanged: { if (visible) today() }

    // Allow time to cross the small gap between the clock and calendar.
    Timer {
        interval: 500
        running: almanac.visible && !almanac.anchorHovered && !calendarHover.hovered
        onTriggered: almanac.visible = false
    }

    component AlmanacButton: Rectangle {
        property string label
        signal clicked()
        implicitWidth: 30
        implicitHeight: 26
        radius: 4
        color: area.containsMouse ? "#30474A" : "#192D32"
        border.width: 1
        border.color: "#42615F"
        Text {
            anchors.centerIn: parent
            text: parent.label
            color: "#DCC998"
            font.family: "JetBrains Mono"
            font.pixelSize: 13
        }
        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: parent.clicked()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: "#101D21"
        border.width: 1
        border.color: "#36565C"
        focus: true
        HoverHandler { id: calendarHover }
        Keys.onEscapePressed: almanac.visible = false

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 10
            RowLayout {
                Text {
                    Layout.fillWidth: true
                    text: "LUMIÈRE ALMANAC"
                    color: "#73DACA"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 15
                    font.bold: true
                }
                AlmanacButton { label: "×"; onClicked: almanac.visible = false }
            }
            RowLayout {
                AlmanacButton { label: "‹"; onClicked: almanac.moveMonth(-1) }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: Qt.formatDateTime(almanac.month, "MMMM yyyy")
                    color: "#E8E6DD"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 14
                }
                AlmanacButton { label: "›"; onClicked: almanac.moveMonth(1) }
            }
            GridLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                columns: 7
                columnSpacing: 3
                rowSpacing: 3
                Repeater {
                    model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                    Text {
                        required property string modelData
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        color: "#E9C46A"
                        font.family: "JetBrains Mono"
                        font.pixelSize: 12
                    }
                }
                Repeater {
                    model: 42
                    Rectangle {
                        required property int index
                        readonly property date day: almanac.cellDate(index)
                        readonly property bool isToday: day.getFullYear() === almanac.now.getFullYear()
                            && day.getMonth() === almanac.now.getMonth() && day.getDate() === almanac.now.getDate()
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.minimumHeight: 24
                        radius: 4
                        color: isToday ? "#28484C" : "transparent"
                        border.width: isToday ? 1 : 0
                        border.color: "#73DACA"
                        Text {
                            anchors.centerIn: parent
                            text: parent.day.getDate()
                            color: parent.isToday ? "#73DACA"
                                : parent.day.getMonth() === almanac.month.getMonth() ? "#E8E6DD" : "#728C86"
                            font.family: "JetBrains Mono"
                            font.pixelSize: 13
                            font.bold: parent.isToday
                        }
                    }
                }
            }
            RowLayout {
                AlmanacButton { label: "Today"; implicitWidth: 65; onClicked: almanac.today() }
                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignRight
                    text: "Expeditions completed today: " + almanac.completedToday
                    color: "#9DC6A5"
                    font.family: "JetBrains Mono"
                    font.pixelSize: 10
                }
            }
        }
    }
}
