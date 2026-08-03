import QtQuick

import Logos.Theme

// Background override for a LogosButton sitting on a card (backgroundSecondary
// surface), so it stands out instead of blending in. Overriding the background
// means owning the state styling too: hover/press are reproduced here from the
// parent control's isActive.
Rectangle {
    readonly property bool on: parent ? parent.enabled : true
    readonly property bool active: on && (parent ? parent.isActive : false)

    // Solid fills (not the DS's translucent backgroundMuted, which composites with
    // the card behind it and renders inconsistently).
    color: on ? Theme.palette.backgroundButton : Theme.palette.surfaceRaised
    radius: parent ? parent.radius : Theme.spacing.radiusXlarge
    border.width: 1
    border.color: active ? Theme.palette.overlayOrange : Theme.palette.borderStrong
}
