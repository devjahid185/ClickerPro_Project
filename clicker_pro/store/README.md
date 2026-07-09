# Graphy7 — Store Listing Assets

Upload these in the store consoles (code can't set store listings — they live in
Google Play Console / App Store Connect).

## App name (already set in the build)
- **Studio app:** `Graphy7`  · package `com.clickerpro.app`
- **Admin app:** `Graphy7 Admin`  · package `com.clickerpro.proadmin`

The launcher label comes from `android/app/build.gradle.kts`
(`manifestPlaceholders["appLabel"]`) and the in-app title from each
`MaterialApp(title:)`. The store **listing name** is set separately in each
console — use "Graphy7" / "Graphy7 Admin" to match.

## Icons
| File | Size | Where |
|------|------|-------|
| `graphy7_playstore_512.png` | 512×512, no alpha | Google Play Console → Store listing → **App icon** |
| `graphy7_appstore_1024.png` | 1024×1024, no alpha | App Store Connect → App Information → **App icon (marketing)** |

Both are the white-background orange G7 mark (matches the on-device launcher
icon). The on-device adaptive/launcher icons are generated separately by
`flutter_launcher_icons` from `assets/icon/app_icon*.png` — do not confuse the
two: those ship inside the APK; the files here are for the store pages only.

## Regenerating
The master is `assets/icon/app_icon.png` (1024×1024, white bg). To re-export:
- App Store 1024: copy the master as-is.
- Play 512: downscale the master to 512×512 (LANCZOS).
