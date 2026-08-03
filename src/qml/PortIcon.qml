import QtQuick

// Right arrow pattern — manual port forwarding
//   . . ● . .
//   . . . ● .
//   ● ● ● ● ●
//   . . . ● .
//   . . ● . .
DotIcon {
    pattern: [
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0,
        1, 1, 1, 1, 1,
        0, 0, 0, 1, 0,
        0, 0, 1, 0, 0
    ]
}
