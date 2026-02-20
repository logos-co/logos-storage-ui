import QtQuick
import QtQuick.Layouts
import Logos.Theme
import Logos.Controls

LogosStorageLayout {
    id: root

    signal completed(bool isGuide)

    property int selectedMode: -1 // 0 = guide, 1 = advanced

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.spacing.medium
        width: 430

        LogosText {
            text: "Logos Storage"
            font.pixelSize: Theme.typography.titleText
            Layout.alignment: Qt.AlignHCenter
        }

        LogosText {
            text: "How would you like to set up your node?"
            font.pixelSize: Theme.typography.primaryText
            Layout.alignment: Qt.AlignHCenter
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Item {
            height: Theme.spacing.medium
        }

        Row {
            spacing: Theme.spacing.medium
            Layout.alignment: Qt.AlignHCenter

            // ── Guide card ───────────────────────────────────────────────
            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 0 ? Qt.rgba(1, 1, 1,
                                                         0.08) : "transparent"
                border.color: root.selectedMode === 0 ? "white" : Qt.rgba(1, 1,
                                                                          1,
                                                                          0.2)
                border.width: root.selectedMode === 0 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    // Nothing OS dot icon like
                    Grid {
                        columns: 5
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 1, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0]
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 2
                                color: "white"
                                opacity: modelData ? 0.9 : 0.1
                            }
                        }
                    }

                    Text {
                        text: "Guide"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Step-by-step setup.\nRecommended for\nmost users."
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedMode = 0
                }
            }

            // ── Advanced card ────────────────────────────────────────────
            Rectangle {
                width: 190
                height: 230
                radius: 14
                color: root.selectedMode === 1 ? Qt.rgba(1, 1, 1,
                                                         0.08) : "transparent"
                border.color: root.selectedMode === 1 ? "white" : Qt.rgba(1, 1,
                                                                          1,
                                                                          0.2)
                border.width: root.selectedMode === 1 ? 2 : 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 14

                    // Nothing OS dot icon like
                    Grid {
                        columns: 5
                        spacing: 4
                        Layout.alignment: Qt.AlignHCenter

                        Repeater {
                            model: [1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 1, 0, 1, 0, 0, 0, 1]
                            Rectangle {
                                width: 6
                                height: 6
                                radius: 2
                                color: "white"
                                opacity: modelData ? 0.9 : 0.1
                            }
                        }
                    }

                    Text {
                        text: "Advanced"
                        color: "white"
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }

                    Text {
                        text: "Manual JSON\nconfiguration for\nexperienced users."
                        color: Qt.rgba(1, 1, 1, 0.55)
                        font.pixelSize: 12
                        horizontalAlignment: Text.AlignHCenter
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredWidth: 150
                        wrapMode: Text.WordWrap
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.selectedMode = 1
                }
            }
        }

        Item {
            height: Theme.spacing.small
        }

        LogosStorageButton {
            text: "Continue"
            enabled: root.selectedMode !== -1
            onClicked: root.completed(root.selectedMode === 0)
            Layout.alignment: Qt.AlignHCenter
        }
    }
}
