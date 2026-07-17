import QtQuick

import Logos.Theme

// Background override for a LogosIconButton: the fill stays constant and only
// the border reacts to hover/press (read from the parent control's isActive).
// Reproduces the DS icon-button look minus the fill change.
Rectangle {
    readonly property bool active: parent && parent.enabled && parent.isActive
    color: Theme.palette.backgroundButton
    radius: Theme.spacing.radiusPill
    border.width: 1
    border.color: active ? Theme.palette.overlayOrange : Theme.palette.borderStrong
}
