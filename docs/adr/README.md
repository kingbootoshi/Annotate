# ADRs — Annotate Fork

Read these before changing this codebase. They extend the core constitution (one canonical path, structural gates, one owner per concept).

| # | Law | One line |
|---|-----|----------|
| [0001](0001-overlay-gated-effects.md) | Overlay-Gated Effects | No visual or audible effect renders unless an annotation overlay is visible; the gate is structural, never a per-feature setting. |
| [0002](0002-single-width-authority.md) | One Width Authority | `annotationLineWidth` on the cursor manager is the sole width truth; all previews derive from it; ink-contact previews are exact-size. |
