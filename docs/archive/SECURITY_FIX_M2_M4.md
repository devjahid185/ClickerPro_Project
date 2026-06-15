# Security Fix Report — M2, M4 (Medium)

> Date: 2026-06-08
> Approved scope: **M2 + M4 only**. Minimal safe implementation; no business
> logic / UI / API-contract changes (except a security-necessary 429 on OTP lockout).

---

## M2 — Mass-assignment protection (role / plan / is_active / manager_permissions)

**1. Root cause**
The `User` model had all privilege fields (`role`, `plan`, `is_active`,
`manager_permissions`) in `$fillable`. Although no current path passed raw
`request->all()`, this left a latent mass-assignment hole: any future
`User::create($request->...)`/`update($request->...)` could let a user set
their own role/plan. (C1 was the concrete instance of this class.)

**2. Security impact** (🟡 Medium, OWASP A08/A01)
Privilege escalation surface — a user could potentially elevate their role to
ADMIN or upgrade their own plan by injecting fields into a registration/profile
payload.

**3. Applied fix**
- Moved the 4 privilege fields out of `$fillable` into `$guarded` on `User`, so
  they can **never** be mass-assigned from request input.
- Updated every **legitimate, authorized** write path to set these fields
  explicitly via `forceFill([...])->save()`:
  - `AuthController::register` (role/plan/is_active)
  - `AuthController::acceptInvite` (role/plan/is_active/manager_permissions)
  - `AdminController::updateUser / setRole / setPlan / setSuspend` (admin-gated)
  - `TeamController::updatePermissions` (manager_permissions, already H1-guarded)
  - `DatabaseSeeder` (admin/owner seed roles)
- `ProfileController::update` already used a validated whitelist (no privilege
  fields) — now doubly safe since the model also guards them.

**4. Files changed**
- `app/Models/User.php` (fillable/guarded)
- `app/Http/Controllers/Api/AuthController.php` (register, acceptInvite)
- `app/Http/Controllers/Api/AdminController.php` (updateUser, setRole, setPlan, setSuspend)
- `app/Http/Controllers/Api/TeamController.php` (updatePermissions)
- `database/seeders/DatabaseSeeder.php`

---

## M4 — OTP brute-force: per-account attempt cap

**1. Root cause**
`verifyOtp` matched the submitted code directly; a wrong code simply found no
row and returned 422 with **no attempt counting**. Only the IP-based
`throttle:6,1` limited guessing — a distributed attacker could still grind the
6-digit code.

**2. Security impact** (🟡 Medium, OWASP A07)
Brute-force of the 6-digit OTP (1,000,000 space) was feasible across IPs,
weakening OTP-based verification/2FA.

**3. Applied fix**
- Added an `attempts` column to `otp_codes` (migration).
- Rewrote `verifyOtp` to fetch the latest active OTP for the user+purpose
  (independent of the submitted code), then:
  - if `attempts >= 5` → invalidate the OTP and return **429** "Too many
    attempts. Request a new OTP." (forces a fresh code);
  - else compare the code with `hash_equals` (constant-time); on mismatch,
    `increment('attempts')` and return 422;
  - on match, mark used and return 200.
- Normal UX preserved: a legitimate user enters the right code first try (200);
  if they mistype a few times they simply request a new OTP. Works alongside
  the existing IP throttle (defense-in-depth).

**4. Files changed**
- `database/migrations/..._add_attempts_to_otp_codes_table.php` (new)
- `app/Models/OtpCode.php` (fillable + cast)
- `app/Http/Controllers/Api/AuthController.php` (verifyOtp)

---

## Verification Results

| Check | Result |
|-------|--------|
| `php -l` (all changed) | ✅ No syntax errors |
| Migration applied | ✅ `attempts` column added |
| **M2 — normal registration** | ✅ FREELANCER signup → role/plan/is_active set correctly via forceFill |
| **M2 — normal profile update** | ✅ name updates; works |
| **M2 — unauthorized role assignment blocked** | ✅ profile PATCH with `role:ADMIN` → **ignored** (stays FREELANCER) |
| **M2 — unauthorized plan assignment blocked** | ✅ profile PATCH with `plan:PRO` → **ignored** (stays FREE) |
| **M2 — admin legit role/plan change** | ✅ admin `setPlan` → PRO applied (forceFill works) |
| **M4 — OTP flow works** | ✅ request 200 (no leak), correct code path intact |
| **M4 — excessive attempts blocked** | ✅ attempts increment; at 5 → **429** "Too many attempts" + OTP invalidated |
| **M4 — legitimate verify** | ✅ fresh OTP + correct code → 200 (request a new code after lockout) |
| No regressions | ✅ owner login 200; admin flows intact; test accounts cleaned |

> Verification via live API + tinker (no PHPUnit suite for these endpoints).
> Note: the IP `throttle:6,1` on auth routes can mask the per-account cap during
> rapid testing; the cap logic was confirmed directly (attempts=5 → 429).

---

## Updated Remaining Findings

All **Critical** and **High** are fixed. Remaining from `SECURITY_AUDIT.md`:

| # | Finding | Severity | Status |
|---|---------|----------|--------|
| C1–C3 | Registration role / OTP leak / invite | 🔴 Critical | ✅ Fixed |
| H1–H2 | Team-perms IDOR / reset-token expiry | 🟠 High | ✅ Fixed |
| **M2** | Mass-assignment | 🟡 Medium | ✅ **Fixed (this report)** |
| **M4** | OTP attempt cap | 🟡 Medium | ✅ **Fixed (this report)** |
| M1 | Auth responses return full user (incl. `public_booking_token`, `manager_permissions`) | 🟡 Medium | ⏳ Open |
| M3 | Web/Admin JWT in `localStorage` (mitigated by CSP/TTL) | 🟡 Medium | ⏳ Open |
| L1 | 2FA `secret` returned in setup response (expected) | 🟢 Low | ⏳ Open |
| L2 | `APP_DEBUG=true`/`APP_ENV=local` (deploy config) | 🟢 Low | ⏳ Open |
| — | Dependency CVE scan (`composer audit`/`npm audit`/`flutter pub outdated`) | follow-up | ⏳ Open |

**Recommended next:** M1 (trim auth response via a UserResource) is the only
remaining application-code Medium; M3/L1/L2 are config/deploy hardening; the
dependency scan is a quick follow-up.

---

## Result
- ✅ M2 + M4 fixed with minimal, verified changes
- ✅ Privilege escalation via mass-assignment closed; OTP brute-force capped
- ✅ Normal registration, profile, admin, and OTP flows preserved
- ⏹️ **Stopped after M2, M4. M1 / M3 / L1 / L2 / dep-scan remain — awaiting approval.**
