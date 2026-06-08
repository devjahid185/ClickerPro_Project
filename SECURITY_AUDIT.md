# ClickerPro — Deep Security Audit (Phase 10)

> Date: 2026-06-08
> Auditor: Senior Security Engineer (read-only — **no code modified**)
> Scope: laravel_backend, web_app, admin_panel, clicker_pro (Flutter)
> Note: builds on the earlier hardening (rate-limit, IDOR fixes, headers, CSP,
> token expiry — all verified still in place). This pass goes deeper into the
> **auth/registration/OTP/invite** flows and maps to OWASP Top 10 (2021).

Severity: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low

---

## Executive Summary

| # | Finding | OWASP | Severity |
|---|---------|-------|----------|
| C1 | Self-assignable `role` on public `register` → anyone can create an ADMIN | A01 Broken Access Control | 🔴 Critical |
| C2 | OTP code returned in the `requestOtp` API response | A02 / A07 | 🔴 Critical |
| C3 | `acceptInvite` is public + accepts arbitrary `user_id` → privilege escalation to MANAGER | A01 | 🔴 Critical |
| H1 | `TeamController.updatePermissions` has no ownership/authz check (IDOR) | A01 | 🟠 High |
| H2 | `forgotPassword`/`resetPassword` token has no expiry check | A07 | 🟠 High |
| M1 | `register`/`login` return full user incl. `public_booking_token`, `manager_permissions` | A01 / excessive data | 🟡 Medium |
| M2 | Mass-assignment: `role`,`plan`,`is_active`,`manager_permissions` in `$fillable` | A08 | 🟡 Medium |
| M3 | Web/Admin JWT in `localStorage` (XSS-exfiltratable) | A05 | 🟡 Medium (mitigated) |
| M4 | OTP verify has no per-account attempt cap (only IP throttle) | A07 | 🟡 Medium |
| L1 | 2FA `secret` returned in setup response (expected, but note) | A02 | 🟢 Low |
| L2 | `APP_DEBUG=true`/`APP_ENV=local` in current `.env` | A05 | 🟢 Low (prod-config) |

**Verified-good (no action):**
- ✅ No hardcoded secrets / API keys / passwords in source
- ✅ Passwords bcrypt-hashed (`password => hashed` cast); `$hidden` excludes password/totp_secret
- ✅ Eloquent everywhere → no SQL injection
- ✅ Rate limiting present (auth 6/min, public 30/min, protected 120/min)
- ✅ IDOR fixes on Payment/Assignment/Task/ReEdit/Invoice (Phase 0) intact
- ✅ Security headers + CSP (backend middleware + next configs)
- ✅ Sanctum token 7-day expiry; file upload MIME allow-list
- ✅ Flutter tokens in `flutter_secure_storage` (Keychain/Keystore)
- ✅ `public_booking_token` is a UUID (not guessable)

---

## Critical Findings

### 🔴 C1 — Privilege escalation via self-assigned role on registration
**OWASP:** A01 Broken Access Control
**Description:** `AuthController::register` validates `role` against the full
enum **including `ADMIN`** and assigns it directly:
```php
'role' => 'nullable|string|in:OWNER,FREELANCER,BOTH,MANAGER,ADMIN',
...
'role' => $data['role'] ?? 'OWNER',
```
Anyone hitting the public `POST /api/auth/register` with `{"role":"ADMIN"}`
becomes a full admin.
**Impact:** Complete platform compromise — admin panel access, all users' data,
broadcasts, feature flags, CSV export of every studio.
**Recommended Fix:** Never accept `role` from registration input. Force
`role = 'OWNER'` (or a safe default); drop `role` from the validated set.
Elevated roles only via the existing admin endpoints / invite flow.
**Files:** `laravel_backend/app/Http/Controllers/Api/AuthController.php` (register)

### 🔴 C2 — OTP returned in API response
**OWASP:** A02 Cryptographic Failures / A07 Auth Failures
**Description:** `requestOtp` returns the freshly generated code to the caller:
```php
return response()->json(['message' => 'ok', 'otp' => $code]);
```
**Impact:** The OTP "second factor" is worthless — any client (or attacker who
can trigger the request for a victim email) reads the code straight from the
HTTP response, fully defeating OTP-based verification/2FA.
**Recommended Fix:** Remove `'otp' => $code` from the response. Deliver the OTP
out-of-band (SMS/email). Return only `{message:'ok'}`. (Was likely left in for
local testing.)
**Files:** `AuthController.php` (requestOtp)

### 🔴 C3 — Public invite acceptance with arbitrary user_id
**OWASP:** A01 Broken Access Control
**Description:** `POST /api/auth/accept-invite` is **public** (no auth) and takes
`user_id` from the body, then promotes that user to `MANAGER` with the
inviter's `ownerId`:
```php
$invitee = User::findOrFail($data['user_id']);
$invitee->update(['role' => 'MANAGER', 'manager_permissions' => [...]]);
```
**Impact:** With any valid (unused) invite code, an attacker can promote **any
user id** to MANAGER under an owner — privilege escalation + account hijack of
the team scope. The acting user is never authenticated as the invitee.
**Recommended Fix:** Require `auth:sanctum`; derive the invitee from
`$request->user()->id` (not the body); validate the code belongs to the
expected owner. Do not trust a client-supplied `user_id`.
**Files:** `AuthController.php` (acceptInvite), `routes/api.php`

---

## High Findings

### 🟠 H1 — Missing authorization on team permission updates (IDOR)
**OWASP:** A01
**Description:** `TeamController::updatePermissions($userId)` looks up any user by
id and overwrites their `manager_permissions` with no check that the caller owns
that team member or is even allowed to manage them.
**Impact:** Any authenticated user can grant themselves (or others)
`can_see_finance` / `can_manage_team` etc. on arbitrary accounts → privilege
escalation, finance data exposure.
**Recommended Fix:** Verify the target user belongs to the caller's team
(`manager_permissions->ownerId === caller id`) or caller is the owner/admin;
else 403.
**Files:** `TeamController.php` (updatePermissions)

### 🟠 H2 — Password-reset token never expires
**OWASP:** A07
**Description:** `resetPassword` checks the hashed token matches but never checks
`created_at` age. A reset token (and the `password_reset_tokens` row) remains
valid indefinitely.
**Impact:** A leaked/old reset token can be used at any later time to take over
an account.
**Recommended Fix:** Reject tokens older than N minutes (e.g. 60) using the
stored `created_at`; delete expired rows.
**Files:** `AuthController.php` (resetPassword)

---

## Medium Findings

### 🟡 M1 — Excessive user data in auth responses
`register`/`login` return the full `$user`. `$hidden` correctly removes
`password`/`totp_secret`, but `public_booking_token` and `manager_permissions`
are still exposed. The booking token is a capability (anyone with it can submit
public bookings as that studio).
**Fix:** Return a trimmed user resource (id, name, email, role, plan,
business_name) — not the raw model.
**Files:** `AuthController.php`, (ideally a `UserResource`)

### 🟡 M2 — Mass-assignment surface on User
`$fillable` includes `role`, `plan`, `is_active`, `manager_permissions`,
`public_booking_token`. Any controller doing `User::create($request->all())`
or `$user->update($data)` with unfiltered input could let a user set these.
(C1 is the concrete instance.) `register` is the active risk; others should be
audited.
**Fix:** Remove privilege fields from `$fillable` or guard each write path; set
them only via explicit, authorized code.
**Files:** `app/Models/User.php` + write paths

### 🟡 M3 — JWT in localStorage (XSS exfiltration)
Web + admin store the bearer token in `localStorage`, readable by any injected
script. **Mitigated** by the CSP + security headers + short token TTL added
earlier, and React's auto-escaping (no `dangerouslySetInnerHTML` found), but
httpOnly cookies would be stronger. Accept-with-mitigations or plan a cookie
migration.
**Files:** `web_app/src/lib/api.ts`, `admin_panel/lib/api.ts`

### 🟡 M4 — No per-account OTP attempt cap
`verifyOtp` relies only on the IP-based `throttle:6,1`. A distributed attacker
could still grind a 6-digit code. Add a per-(user,purpose) attempt counter /
lockout, and invalidate the OTP after N failures.
**Files:** `AuthController.php` (verifyOtp), OtpCode model

---

## Low Findings

### 🟢 L1 — 2FA secret in setup response
`security/2fa/setup` returns the TOTP `secret` (and an otpauth URL). This is
**expected** for authenticator enrollment, but ensure the endpoint is only
reachable by the authenticated owner (it is — `auth:sanctum`) and consider
returning only the QR/otpauth, not the raw base32, if the client renders the QR.
**Files:** `SecurityController.php` (twoFaSetup)

### 🟢 L2 — Debug/env flags
Current `.env` has `APP_DEBUG=true`, `APP_ENV=local` — fine for dev, must be
`false`/`production` before public exposure (already templated in
`.env.production.example`).
**Files:** `.env` (deploy config)

---

## OWASP Top 10 (2021) Coverage

| OWASP | Status |
|-------|--------|
| A01 Broken Access Control | ⚠️ **C1, C3, H1** open (registration role, invite, team perms) |
| A02 Cryptographic Failures | ⚠️ C2 (OTP leak); passwords bcrypt ✅ |
| A03 Injection | ✅ Eloquent ORM, no raw SQL; React escaping |
| A04 Insecure Design | ⚠️ OTP/invite trust model (C2/C3) |
| A05 Security Misconfiguration | 🟡 M3 localStorage, L2 debug; headers/CSP ✅ |
| A06 Vulnerable Components | ℹ️ Not deep-scanned — run `composer audit` / `npm audit` (see note) |
| A07 Auth Failures | ⚠️ H2 (reset expiry), M4 (OTP cap); rate-limit ✅ |
| A08 Data Integrity Failures | 🟡 M2 mass-assignment |
| A09 Logging Failures | ✅ LoginActivity logged; scrub secrets in prod logs |
| A10 SSRF | ✅ No server-side fetch of user URLs found |

> **A06 note:** dependency CVE scanning was not part of this static pass.
> Recommend running `composer audit` (Laravel) and `npm audit` (web/admin) and
> `flutter pub outdated` as a follow-up.

---

## Recommended Remediation Order (await approval — nothing changed)

1. **C1, C2, C3** (Critical) — registration role, OTP leak, invite auth. Small,
   high-impact, behavior-preserving for legit flows.
2. **H1, H2** (High) — team-permission authz, reset-token expiry.
3. **M1, M2, M4** (Medium) — trim auth response, lock down fillable, OTP cap.
4. **M3, L1, L2** (config/defense-in-depth) — as part of deploy hardening.

**No code modified in this phase.** Reply with which findings to fix.
