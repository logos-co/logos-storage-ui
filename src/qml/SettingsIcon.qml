import QtQuick

// Gear / cog icon — 4 cardinal teeth + ring with center hole
//   . . ●. .
//   . ● ● ● .
//   ● ● . ● ●
//   . ● ● ● .
//   . . ● . .
DotIcon {
    pattern: [0, 0, 0, 0, 0, 0, 1, 1, 1, 0, 1, 1, 0, 1, 1, 0, 1, 1, 1, 0, 0, 0, 1, 0, 0]
}
