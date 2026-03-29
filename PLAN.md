# Anihortes Keyboard — Implementation Plan

## Phase 1: Core Key Layout & Tap Input

**Goal**: Render the 3x3 grid, spacebar, and side buttons; handle taps to insert primary characters.

### 1.1 Define the key data model
- Create a `KeyDefinition` struct mapping each key's center character and its 8 directional characters (N, NE, E, SE, S, SW, W, NW).
- Populate the full character map from the CLAUDE.md layout for all 9 keys.
- Define an enum for special actions: `.com`, case-up, case-down, tab, compose (placeholder), accent/diaeresis.

### 1.2 Build the keyboard grid view
- Replace the boilerplate in `KeyboardViewController` with a programmatic UIKit layout.
- Create a 3x3 grid of key views, a full-width spacebar below, and a column of 4 side buttons (globe/world, abc/123, backspace, return) to the right.
- Each key view shows the center character prominently, with small hint labels for the 8 surrounding characters (like MessagEase's visual hints).
- Use Auto Layout to size keys proportionally and adapt to different screen widths.

### 1.3 Handle tap to insert center character
- Wire up tap gestures on each key view.
- On tap (no significant drag), insert the center character via `textDocumentProxy.insertText()`.
- Wire spacebar to insert " ", backspace to `deleteBackward()`, return to insert "\n", and globe to `advanceToNextInputMode()`.

### 1.4 Numeric mode toggle
- Create a second set of `KeyDefinition`s for numeric mode (1-9, 0+space layout per CLAUDE.md).
- abc/123 button toggles between the two layouts, re-rendering the grid.

**Milestone**: Keyboard appears, tapping keys types the center characters, mode switching works.

---

## Phase 2: Swipe Gesture Recognition

**Goal**: Detect directional swipes starting from a key and insert the corresponding character.

### 2.1 Implement gesture recognizer
- Add a custom `UIPanGestureRecognizer` (or handle touches directly via `touchesBegan`/`touchesMoved`/`touchesEnded`) on each key view.
- On touch-down, record the starting point.
- On touch-up, compute the displacement vector. If the distance exceeds a threshold (~20pt, tunable), determine the closest of 8 cardinal directions (N, NE, E, SE, S, SW, W, NW) using the angle.
- If below threshold, treat as a tap (center character).

### 2.2 Map direction to character and insert
- Look up the directional character from the `KeyDefinition`.
- If the slot is a normal character, insert it.
- If the slot is a special action, handle it (see Phase 3).

### 2.3 Visual feedback during swipe
- On drag, highlight or animate the key to show which direction is being selected.
- Show the candidate character in an enlarged preview (similar to iOS key magnification).

**Milestone**: All ~80 characters/symbols are typeable via tap + swipe.

---

## Phase 3: Special Keys & Actions

**Goal**: Implement non-character actions mapped to certain swipe positions.

### 3.1 Case conversion (↑ / ↓)
- ↑ (swipe N from "r" key): Set a shift state so the NEXT character typed is uppercase.
- ↓ (swipe S from "r" key): Set a shift state so the NEXT character typed is lowercase (overrides auto-capitalization).
- Visual indicator on the keyboard when shift is active.

### 3.2 Accent / diaeresis (◌̈) and other accents
- Accents (◌̈, ^, `, ') attempt to combine with the previously typed character when it makes sense (e.g., e + ◌̈ → ë).
- "Makes sense" = the combined form exists as a precomposed Unicode character (NFC normalization).
- If the combination doesn't produce a valid precomposed character, insert the accent as a literal character.
- **Backspace undo**: If the user doesn't want the combination, backspace should undo the combining — deleting the combined character and re-inserting the base character + accent as separate characters.

### 3.3 ".com" (✓)
- Swipe S from "h" key inserts the string ".com".

### 3.4 Tab (␉)
- Swipe S from "t" key inserts a tab character "\t".

### 3.5 Backspace behavior
- Single tap: delete one character. If the last action was accent-combining, undo the combine (restore base char + insert accent literally).
- Long press: continuous deletion (with acceleration).

### 3.6 Long press on alpha keys
- Long pressing any key in alphabetic mode types the underlying digit (matching the numeric layout position).

**Milestone**: All special actions work correctly.

---

## Phase 4: Visual Polish & Theming

**Goal**: Make the keyboard look clean and adapt to system appearance.

### 4.1 Light/dark mode
- Detect `textDocumentProxy.keyboardAppearance` and style accordingly.
- Key backgrounds, text colors, and borders should match iOS keyboard conventions.

### 4.2 Key styling
- Rounded rectangle key shapes with subtle shadows/borders.
- Center character in a larger font, directional hints in a smaller font at the edges.
- Side buttons with appropriate SF Symbols (globe, "123"/"abc" label, delete.left, return).

### 4.3 Sizing & safe areas
- Respect keyboard height guidelines.
- Handle safe area insets on devices with home indicators.
- Consider iPhone SE (small) through iPhone Pro Max (large).

### 4.4 Animations
- Subtle key press animation (scale down slightly).
- Swipe direction indicator during gesture.

**Milestone**: Keyboard looks polished and professional on all iPhone sizes.

---

## Phase 5: Main App

**Goal**: The host app provides setup instructions and eventual settings.

### 5.1 Setup instructions view
- Replace the boilerplate ContentView with a step-by-step guide for enabling the keyboard (Settings → General → Keyboard → Keyboards → Add New Keyboard → Anihortes).
- Detect whether the keyboard is already enabled and show status.

### 5.2 Settings (future)
- Placeholder for settings like swipe sensitivity, key size, sound/haptic feedback toggles.
- Settings will need to be communicated to the extension via App Groups (shared UserDefaults).

**Milestone**: App guides the user through keyboard setup.

---

## Phase 6: Refinement & Edge Cases

### 6.1 Haptic feedback
- Add subtle haptic feedback on key press and swipe completion.

### 6.2 Double-space for period
- Optionally: double-tap spacebar inserts ". " (common iOS keyboard behavior).

### 6.3 Auto-capitalization
- Start in caps (first character is uppercase).
- Auto-capitalize after period (deterministic, like standard iOS).
- No guessing, no autocorrect, no predictive text — ever.

### 6.4 Sound feedback
- Optional key click sounds (respecting system settings).

### 6.5 Compose key (future)
- Placeholder infrastructure for the compose key (C at NW of "a" key). Not implemented initially per CLAUDE.md.

### 6.6 World button swipe gestures (future)
- Swiping off the world/globe button to resize, shrink, or reposition the keyboard (left/right side).
- Low priority — start with fixed size.

---

## Implementation Order Summary

| Step | What | Depends On |
|------|------|------------|
| 1.1 | Key data model | — |
| 1.2 | Grid layout | 1.1 |
| 1.3 | Tap input | 1.2 |
| 1.4 | Numeric mode | 1.1, 1.2 |
| 2.1 | Gesture recognizer | 1.2 |
| 2.2 | Direction → character | 1.1, 2.1 |
| 2.3 | Visual feedback | 2.1 |
| 3.x | Special actions | 2.2 |
| 4.x | Visual polish | 1.2 |
| 5.x | Main app | — (parallel) |
| 6.x | Refinements | 3.x, 4.x |

Phases 1-3 are the core functionality. Phase 4-5 can proceed partly in parallel. Phase 6 is iterative polish.
