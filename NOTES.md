# ReefJKN — Architecture and Decision Log

## Architecture at a glance

- `ShortcutController` owns all global key monitoring via the `KeyboardShortcuts` library. It's the single place where mode-aware dispatch lives.
- `CyclePanelController` is mode-agnostic — it just takes an `Application` and shows the switcher. It doesn't know or care where the app came from.
- `ProfileManager` handles persistence for bindings/profiles (JSON in Application Support). Unused in auto mode but kept intact.
- Settings are stored in UserDefaults via `@AppStorage`. `SwitcherMode.userDefaultsKey` is the canonical key string; both the view and the controller use it.

## Key decisions

### Auto mode as default (2026-06-12)
New users get zero-config window switching out of the box — press shortcut, see current app's windows. Bindings mode still available in Preferences → General. Default chosen because it requires no setup and the binding workflow is non-obvious to discover.

### startIndex = 1 in auto mode (2026-06-12)
Since you're always in the front app when you press the shortcut, the first press pre-selects the second window (same as the "already on this app" case in bindings mode). This means the shortcut cycles forward immediately rather than just re-highlighting the window you're already in. If there's only one window, `CyclePanelState` ignores the out-of-bounds startIndex and defaults to 0.

### UserDefaults read on each keypress, not observed (2026-06-12)
`ShortcutController` is not a SwiftUI view, so it reads `UserDefaults.standard` directly in `handleActivate`. This is correct and always reflects the current setting with no observer plumbing.

## Trade-offs made under time pressure

- The segmented picker in General prefs shows "Auto / Bindings" — short labels. If more modes are added later, this control will need to change.
- Frame height in `PreferencesGeneralView` is still hardcoded (now 400/465). Would be better as auto-sizing.

## With more time, I would

- Add a brief onboarding hint the first time auto mode fires (e.g. "Tip: switch to Bindings mode in Preferences to assign apps to number keys").
- Consider disabling/greying out the Profiles tab when in auto mode so the UI is less confusing.

## Things to discuss in a walkthrough

- Is startIndex = 1 the right default for auto mode, or should the first press just show the list at index 0?
- Should the Profiles tab be hidden or greyed out in auto mode?
