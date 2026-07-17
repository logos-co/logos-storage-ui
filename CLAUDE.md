# Logos Storage UI

Filesharing app built on the Logos design system (`Logos.Controls` / `Logos.Theme`,
consumed as a flake input from `logos-design-system`).

## Overriding a design-system component's background

The colors a design-system component ships with are **defaults, not fixed**. When a
DS component doesn't look right in its context, override its `background` (inherited
from QtQuick `Control`) at the usage site — do not hardcode colors, or reintroduce a
local copy of the component.

Overriding `background` replaces the component's own background entirely, so **you
own its state styling too**: reproduce hover / pressed / focus / disabled in the
override, reading them from the control (`parent.isActive`, `parent.textInput.activeFocus`, ...).

To keep this maintainable, define the override background **once** as a reusable
component and reuse it — never a `Rectangle` copy-pasted per call site. See
`CardButtonBackground.qml`: it reads `parent.isActive` and pulls every color from a
`Theme.palette.*` token.

```qml
LogosButton {
    text: "Start"
    background: CardButtonBackground {}   // stands out on the card, hover included
}
```

Rules:
- No hardcoded colors. Always a `Theme.palette.*` token (a named variable), so a
  palette change propagates everywhere.
- Defaults assume the component sits on the page background. Our widgets live inside
  cards (`backgroundSecondary`), so a default-colored button or field blends into the
  card — override its background.
