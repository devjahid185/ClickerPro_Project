# ClickerPro — Dependency Security Audit (A06)

> Date: 2026-06-08
> Mode: **read-only** — no packages updated, no code changed.
> Tools: `composer audit` (Laravel), `npm audit` (web + admin),
> `flutter pub outdated` + manual review (Flutter has no formal CVE audit tool).

---

## Executive Summary

| Ecosystem | Critical | High | Moderate | Low | Total |
|-----------|:--:|:--:|:--:|:--:|:--:|
| Laravel (composer) | 0 | 0 | 0 | 0 | **0** ✅ |
| web_app (npm) | 0 | 1 | 1 | 0 | **2** |
| admin_panel (npm) | 1 | 0 | 1 | 0 | **2** |
| Flutter (pub) | 0 | 0 | 0 | 0 | **0 known CVEs** ✅ |

**Headline:** Both Next.js apps carry the same root issue — an **outdated Next.js
14.x** that bundles a vulnerable `postcss` and has Next-level advisories. The
admin panel's instance is rated **Critical** (Server Actions DoS). The single
remediation for all 4 npm findings is upgrading Next.js. Laravel and Flutter
are clean of known advisories.

---

## 🔴 Critical

### D1 — Next.js DoS via Server Actions (admin_panel)
- **Package:** `next`
- **Current version:** `14.2.15`
- **Severity:** Critical
- **Advisory:** GHSA (Next.js "Denial of Service with Server Actions")
- **Vulnerable range:** `0.9.9 – 16.3.0-canary.5`
- **Exploitability:** Network, unauthenticated — a crafted Server Action request
  can exhaust server resources (DoS). Relevant because the admin panel is a
  Next.js server app. **Mitigating factor:** admin panel is intended for a small
  internal operator audience (not mass public), and behind the recommended WAF
  this is reduced — but still Critical by CVSS.
- **Recommended version:** `next@14.2.x` latest patch that includes the fix, or
  the audit's suggested `16.2.7`. **Prefer the latest 14.2.x patch** to avoid a
  major-version (App Router) migration; verify the fix is backported, else plan
  the Next 15/16 upgrade.

---

## 🟠 High

### D2 — Next.js DoS via Image Optimizer remotePatterns (web_app)
- **Package:** `next`
- **Current version:** `14.2.35`
- **Severity:** High
- **Advisory:** GHSA-9g9p-9gw9-jx7f
- **Vulnerable range:** `9.3.4-canary.0 – 16.3.0-canary.5`
- **Exploitability:** Affects **self-hosted** apps using the Image Optimizer
  with `remotePatterns`. The web app uses `next/image` patterns; an attacker
  could trigger resource exhaustion via the optimizer endpoint. Network,
  unauthenticated.
- **Recommended version:** latest `next@14.2.x` patch with the fix (audit
  suggests `16.2.7`). Same upgrade as D1.

---

## 🟡 Moderate

### D3 — PostCSS XSS via unescaped `</style>` in CSS stringify (web_app + admin_panel)
- **Package:** `postcss` (transitive, via Next.js build toolchain)
- **Current version:** `8.4.31` (web); same class in admin
- **Severity:** Moderate
- **Advisory:** GHSA-qx2v-qp2m-jg93
- **Fixed in:** `postcss >= 8.5.10`
- **Exploitability:** XSS only if untrusted CSS is processed through PostCSS
  stringify. In this project PostCSS runs at **build time** on first-party CSS
  (Tailwind/landing styles), not on user input — so practical exploitability is
  **low** here. Still flagged because the version is vulnerable.
- **Recommended version:** pulled in automatically by the Next.js upgrade
  (Next bundles postcss); or bump `postcss` to `>=8.5.10`.

---

## ✅ Clean

### Laravel (composer audit)
- `No security vulnerability advisories found.` — 0 findings.
- `laravel/framework ^12.0`, `laravel/sanctum` — current.

### Flutter (pub)
- **No known CVE-flagged packages.** Dart/Flutter has no formal `audit`
  command; manual review shows:
  - All dependencies sourced from **pub.dev** (no `git:`/`path:` overrides, no
    `dependency_overrides`) → low supply-chain risk.
  - Security-sensitive packages are recent: `flutter_secure_storage ^10.3.1`,
    `http ^1.6.0`, `url_launcher ^6.3.0`.
  - **Version lag (not vulnerabilities):** several packages are behind latest
    (`flutter_riverpod 2.6.1→3.x`, `google_sign_in 6.3→7.2`,
    `connectivity_plus 6.1→7.1`, `drift 2.31→2.33`). These are upgrades, not
    security advisories.
  - **EOL note:** `sqlite3_flutter_libs` resolvable is `0.6.0+eol` — end-of-life
    flag, not a CVE; plan a migration path eventually.

---

## Findings Table (quick reference)

| ID | Package | Current | Severity | Advisory | Fixed in | Exploitability |
|----|---------|---------|----------|----------|----------|----------------|
| D1 | next (admin) | 14.2.15 | 🔴 Critical | Server Actions DoS | latest 14.2.x / 16.2.7 | Network, unauth DoS |
| D2 | next (web) | 14.2.35 | 🟠 High | GHSA-9g9p-9gw9-jx7f | latest 14.2.x / 16.2.7 | Self-hosted image optimizer DoS |
| D3 | postcss (web+admin) | 8.4.31 | 🟡 Moderate | GHSA-qx2v-qp2m-jg93 | 8.5.10 (via Next) | Low (build-time, first-party CSS) |

---

## Recommended Remediation (await approval — nothing applied)

1. **Upgrade Next.js in admin_panel and web_app** — closes D1, D2, and D3
   (postcss is bundled). Two options:
   - **Conservative:** bump to the **latest `next@14.2.x`** patch (stays on
     Pages/App router as-is; lowest risk). Verify the patch includes the
     Server-Actions + Image-Optimizer fixes.
   - **Forward:** migrate to **Next 15/16** (the audit's `fixAvailable: 16.2.7`)
     — larger change; needs build + route testing.
   - Recommendation: try the conservative 14.2.x patch first; only go major if
     the fix isn't backported.
2. **Flutter:** no security action required now. Optionally schedule the version
   upgrades and `sqlite3_flutter_libs` EOL migration as maintenance.
3. **Re-run** `npm audit` / `composer audit` after any upgrade to confirm 0.

> Each upgrade must be followed by `npm run build` + smoke test of web & admin,
> since a Next bump can touch config/build. **No package was changed in this audit.**
