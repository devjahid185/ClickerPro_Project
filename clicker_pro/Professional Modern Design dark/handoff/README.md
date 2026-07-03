# ClickerPro — Dark Theme Handoff (for Claude Code → Flutter)

This folder is everything Claude Code needs to build the **ClickerPro dark theme ("Noir")** as a **Flutter** app. It is a standalone, new modern aesthetic — separate from the existing light theme.

## What's inside
1. **`CLICKERPRO_DARK_FLUTTER_SPEC.md`** ← **start here.** Full build spec: Dart color/dimension/text tokens, `ThemeData`, reusable widgets, and a top-to-bottom widget breakdown of all 8 screens.
2. **`ClickerPro-Dark-Visual-Reference.html`** — open in any browser (offline). Shows all 8 screens exactly as they should look. Use it as the visual source of truth alongside the spec.

## How to hand off to Claude Code
Give it the whole folder and this prompt:

> "Build this ClickerPro dark theme as a Flutter app. Read `CLICKERPRO_DARK_FLUTTER_SPEC.md` fully first — it has the design tokens, ThemeData, reusable widgets, and per-screen layout. Open `ClickerPro-Dark-Visual-Reference.html` in a browser to see the exact target look. Build the theme tokens and reusable widgets first (§1–§3), then the screens (§4). Use `google_fonts` for Space Grotesk + JetBrains Mono. Match the reference; this is a standalone theme — do not merge it with any existing light theme."

## Screens covered
Dashboard · Add Booking · Booking List · Event Details · Finance · Packages · Profile & Settings.
