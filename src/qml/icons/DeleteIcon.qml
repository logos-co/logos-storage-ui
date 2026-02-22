import QtQuick

// X pattern — delete / remove
//   ● . . . ●
//   . ● . ● .
//   . . ● . .
//   . ● . ● .
//   ● . . . ●
// qmllint disable unqualified
DotIcon {
    pattern: [
        1, 0, 0, 0, 1,
        0, 1, 0, 1, 0,
        0, 0, 1, 0, 0,
        0, 1, 0, 1, 0,
        1, 0, 0, 0, 1
    ]
}
