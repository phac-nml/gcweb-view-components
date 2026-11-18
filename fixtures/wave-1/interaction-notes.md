# Wave 1 interaction notes

## Menu baseline expectations
- Top navigation reachable by keyboard from skip links/header controls.
- Enter/Space opens menu items with child content.
- Esc closes open menu region and returns focus to trigger.
- Tab/Shift+Tab preserves logical focus order.
- No-JS fallback still exposes essential navigation links.

## Toggle baseline expectations
- Trigger has explicit accessible name and state (`aria-expanded` or equivalent).
- Enter/Space toggles associated region visibility.
- Focus stays predictable when region opens/closes.
- Toggled content remains readable with CSS and JS disabled.

## Capture notes
- Validate behavior on EN and FR pages.
- Record any deviation in the issue using page URL + exact interaction steps.
