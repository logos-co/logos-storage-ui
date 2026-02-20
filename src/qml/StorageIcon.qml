import QtQuick

// Ring / node pattern — used in the StorageView header
DotIcon {
    pattern: [
        0, 1, 1, 1, 0,
        1, 0, 0, 0, 1,
        1, 0, 1, 0, 1,
        1, 0, 0, 0, 1,
        0, 1, 1, 1, 0
    ]
    dotSize: 7
    dotSpacing: 5
}
