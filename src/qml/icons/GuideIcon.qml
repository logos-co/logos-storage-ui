import QtQuick

// Crosshair pattern — step-by-step guide
//   . . ● . .
//   . . ● . .
//   ● ● . ● ●
//   . . ● . .
//   . . ● . .
DotIcon {
    pattern: [
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0,
        1, 1, 0, 1, 1,
        0, 0, 1, 0, 0,
        0, 0, 1, 0, 0
    ]
}
