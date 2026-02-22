import QtQuick

// Diamond / network pattern — UPnP automatic port forwarding
//   . . ● . .
//   . ● . ● .
//   ● . ● . ●
//   . ● . ● .
//   . . ● . .
DotIcon {
    pattern: [
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        1, 0, 1, 0, 1,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0
    ]
}
