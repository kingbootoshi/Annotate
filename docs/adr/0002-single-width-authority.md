# ADR-0002: One Width Authority

Date: 2026-08-26
Status: Accepted

## Decision

Stroke width has exactly one owner per layer, one feed between layers, and exact-size ink previews:

1. **Durable truth:** `UserDefaults.lineWidthKey`. Every mutation (W-picker commit, width slider) writes it in the same code path that updates the runtime value. Reading it is legal only to *initialize* a control (e.g. the slider's starting position) — never to render a live preview.
2. **Runtime drawing truth:** `OverlayView.currentLineWidth`. Every width mutation assigns it on all overlay views; strokes draw with it.
3. **Preview mirror:** `CursorHighlightManager.annotationLineWidth`, fed *only* by `OverlayView.currentLineWidth`'s `didSet`. Cursor rendering reads width exclusively from the manager (`annotationLineWidth` / derived `strokeCursorSize`).

Ink-contact previews are **exact-size**: the brush cursor's ink dot and the "Circle" cursor style render a diameter equal to `annotationLineWidth` — the pointer shows what the stroke lays down.

`activeCursorSize` is the eraser ring's hit-radius only. It never gates or scales a drawing-tool cursor.

Settings-window style thumbnails are demo-scale shape illustrations, not width previews; they are exempt from exact-size but must not read width from anywhere.

## Why

The cursor previously sized from a user setting unrelated to the stroke, so the pointer lied about what drawing would do. Independent width copies drifted the moment one changed. One owner per layer, one feed between layers, exact-size contact previews — the pointer is the stroke.

## Enforcement

- `CursorHighlightView` reads width only through the manager.
- New preview surfaces (HUD, picker, cursor) derive from the manager; only control initialization may read `lineWidthKey`; nothing renders from a private width copy.
