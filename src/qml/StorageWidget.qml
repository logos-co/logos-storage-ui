import QtQuick 2.15
  import QtQuick.Controls 2.15

  Item {
      width: 800
      height: 600

      Column {
          spacing: 12
          anchors.fill: parent
          anchors.margins: 20

          Text { text: storage.statusText; wrapMode: Text.Wrap }
          Row {
              spacing: 8
              Button {
                  text: storage.storageRunning ? "Stop" : "Start"
                  onClicked: storage.startStorage()
              }
              Button {
                  text: "Debug"
                  onClicked: storage.requestDebug()
              }
          }
      }
  }
