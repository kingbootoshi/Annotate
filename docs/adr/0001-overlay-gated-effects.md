# ADR-0001: Every Effect Is Overlay-Gated

Date: 2026-08-26
Status: Accepted

## Decision

No visual or audible effect may render while no annotation overlay is visible. The gate is structural, not a per-feature setting:

- `CursorHighlightManager.isActive` and `CursorHighlightManager.cursorHighlightAvailable` both require `hasAnyActiveOverlay()`. Every effect surface (spotlight, click ripple, hold ring, tool cursors) derives its visibility from these two properties.
- The former `SpotlightRequiresOverlay` opt-in setting is deleted. Overlay-gating is not user-configurable.

## Rules

1. A new effect (layer, window, sound, cursor) MUST derive its visibility from `isActive`, `cursorHighlightAvailable`, or `shouldShowActiveCursorOnScreen(_:)`. Never from its own defaults key alone.
2. Toggling the overlay off MUST be sufficient to remove every effect from screen. If a new effect needs teardown, hook `overlayVisibilityChanged()`.
3. §4 No effect setting may bypass the overlay gate with an "always show" mode.

## Why

Effects leaking past toggle-off (spotlight following the cursor over normal desktop work) breaks the core contract of the app: the toggle is the single switch between "annotating" and "invisible utility". A per-feature opt-in gate proved insufficient in practice - one unchecked box leaked the spotlight system-wide.
