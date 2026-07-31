import QtQuick
import Logos.Theme

// Node status matrix (Figma "Basecamp - MVP v.1", node 246:1382)
//   . ● ● ● .
//   . ● . ● .
//   ● . ● . ●
//   . ● . ● .
//   . ● ● ● .
DotIcon {
    pattern: [0, 1, 1, 1, 0,
              0, 1, 0, 1, 0,
              1, 0, 1, 0, 1,
              0, 1, 0, 1, 0,
              0, 1, 1, 1, 0]
    dotSize: 12
    dotSpacing: 4
    dotRadius: 4
    inactiveDotColor: Theme.palette.border
}
