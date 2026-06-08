# Dependency Fix Report — Next.js (conservative 14.2.x)

> Date: 2026-06-08
> Approved scope: upgrade Next.js to the **latest secure 14.2.x patch only**.
> No Next 15/16. No routing / architecture / business-logic changes.
> Applied separately to web_app and admin_panel.

---

## Key finding up front

- **Latest available 14.2.x = `14.2.35`** (there is no 14.2.36+; 14.2.35 is the
  final 14.2.x release).
- **web_app was already on `14.2.35`** → no upgrade needed.
- **admin_panel was on `14.2.15`** → upgraded to `14.2.35`. This removed the
  **Critical** "Server Actions DoS" and several other advisories.
- **Residual advisories remain on 14.2.35** in both apps. Their `fixAvailable`
  is `next@16.2.7` (`isSemVerMajor: true`) — i.e. **no fix exists on the 14.2.x
  branch**. Per your instruction, work **STOPPED** here; Next 15/16 not attempted.

---

## 1. web_app

| Item | Value |
|------|-------|
| Previous version | `next@14.2.35` |
| New version | `next@14.2.35` (already latest 14.2.x — unchanged) |
| Action | None — already on the latest patch |
| Security findings resolved | None additional possible on 14.2.x |
| Residual | High/Moderate advisories (image optimizer DoS, RSC DoS, rewrite smuggling, middleware cache-poison, CSP-nonce XSS, postcss XSS) — **all require Next ≥15/16** |

## 2. admin_panel

| Item | Value |
|------|-------|
| Previous version | `next@14.2.15` |
| New version | `next@14.2.35` (pinned exact) |
| Action | `npm install next@14.2.35 --save-exact` |
| Advisory count | **24 → 15** |
| Resolved | 🔴 **Critical "Server Actions DoS" eliminated**, plus ~8 other advisories patched within the 14.2.x line |
| Residual | Same class as web_app — 1 high + 1 moderate root advisories needing Next ≥15/16 |

**Files changed:** `admin_panel/package.json` (next pin 14.2.15 → 14.2.35),
`admin_panel/package-lock.json`. No source/routing/config changes.

---

## Build & Verification Results

### admin_panel (upgraded — full verification)
| Check | Result |
|-------|--------|
| `tsc --noEmit` | ✅ 0 errors |
| `npm run build` | ✅ Compiled successfully |
| Lint / new warnings | ✅ none (build clean) |
| Login works | ✅ token issued via proxy |
| Dashboard works | ✅ `/api/admin/stats` → 200 |
| Navigation works | ✅ `/`, `/login`, `/users` → 200 |
| Images work | ✅ no next/image usage broken; build OK |
| API calls work | ✅ login + stats 200 |
| Critical advisory | ✅ removed (Server Actions DoS gone) |

### web_app (unchanged — no upgrade applied)
No change made, so no re-verification required. It remains at the previously
verified-good `14.2.35` (builds, tsc clean from prior phases).

---

## Security Findings Resolved

| ID | App | Finding | Status |
|----|-----|---------|--------|
| D1 | admin_panel | Next.js Critical DoS via Server Actions | ✅ **Resolved** (14.2.15→14.2.35) |
| — | admin_panel | ~8 additional 14.2.x-line advisories | ✅ Resolved by the patch |
| D2 | web_app | Next.js High DoS via Image Optimizer | ⛔ Unresolvable on 14.2.x |
| D3 | web+admin | PostCSS Moderate XSS (transitive via Next) | ⛔ Unresolvable on 14.2.x (bundled by Next) |

---

## Remaining Findings (STOPPED — require approval)

Both apps on `14.2.35` still report (all `fixAvailable: next@16.2.7`, semver-major):

| Severity | Advisory |
|----------|----------|
| High | Image Optimizer `remotePatterns` DoS (GHSA-9g9p-9gw9-jx7f) |
| High | RSC HTTP request deserialization DoS |
| Moderate | HTTP request smuggling in rewrites |
| Moderate | Unbounded next/image disk-cache growth |
| Moderate | Server Components DoS (multiple) |
| Moderate | Middleware/proxy redirect cache-poisoning |
| Moderate | App Router CSP-nonce XSS |
| Moderate | PostCSS `</style>` XSS (build-time, first-party CSS → low practical risk here) |

**None of these have a fix on the Next 14.2.x branch.** Closing them requires a
**major upgrade to Next 15 or 16**, which is explicitly out of the approved scope.

### ⛔ STOP — as instructed
> "If vulnerabilities remain after the latest 14.2.x patch: STOP. Do not proceed
> to Next 15 or 16 without approval."

**I have stopped.** No Next 15/16 migration attempted.

### Recommendation for the next decision
- The residual advisories are mostly **DoS** (availability) and are strongly
  mitigated by the planned **WAF/Cloudflare + reverse proxy** deploy hardening
  (Batch D). The CSP-nonce XSS is mitigated by the existing CSP; the postcss XSS
  is build-time on first-party CSS (low practical risk).
- To fully clear them, schedule a **separate, approved Next 15/16 upgrade**
  (App-Router/config migration + full re-test) as its own task.

---

## Result
- ✅ admin_panel: 14.2.15 → 14.2.35, **Critical DoS resolved**, all checks pass
- ✅ web_app: already on latest 14.2.x; no change needed
- ⛔ Residual advisories require Next 15/16 — **stopped, awaiting approval**
- ✅ No routing / architecture / business-logic changes; conservative scope honored
