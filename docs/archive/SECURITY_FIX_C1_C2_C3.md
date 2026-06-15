# Security Fix Report — C1, C2, C3 (Critical)

> Date: 2026-06-08
> Approved scope: **C1, C2, C3 only**. Smallest safe changes; preserve existing
> user flows, business logic, and UI behavior. (H1/H2/Medium/Low NOT touched.)
> All changes are in one file: `laravel_backend/app/Http/Controllers/Api/AuthController.php`.

---

## C1 — Privilege escalation via self-assigned role on registration

**1. Root cause**
`register()` validated `role` against the full enum **including `ADMIN`/`MANAGER`**
and assigned it directly from request input (`'role' => $data['role'] ?? 'OWNER'`).

**2. Security impact** (🔴 Critical, OWASP A01)
Anyone could `POST /api/auth/register` with `{"role":"ADMIN"}` and obtain a full
admin account → total platform compromise (admin panel, all studios' data,
feature flags, CSV exports).

**3. Applied fix**
Restricted the accepted `role` to self-service roles only:
`'role' => 'nullable|string|in:OWNER,FREELANCER,BOTH'`.
`ADMIN` and `MANAGER` are now rejected by validation (422). Default stays
`OWNER`. Legitimate self-service signups (OWNER/FREELANCER/BOTH) are unchanged.
MANAGER continues to come only through the invite flow (C3).

**4. Files changed**
`laravel_backend/app/Http/Controllers/Api/AuthController.php` → `register()`

---

## C2 — OTP code returned in the API response

**1. Root cause**
`requestOtp()` returned the generated code to the caller:
`return response()->json(['message' => 'ok', 'otp' => $code]);` (left over from
local testing).

**2. Security impact** (🔴 Critical, OWASP A02/A07)
The OTP "second factor" was readable straight from the HTTP response, fully
defeating OTP verification/2FA — any caller (or attacker triggering it for a
victim email) could read the code.

**3. Applied fix**
Removed `'otp' => $code` from the response; now returns only `{message:'ok'}`.
The OTP is still generated and stored (10-min expiry) so `verifyOtp` works
exactly as before — it must now be delivered out-of-band (SMS/email driver is a
follow-up backend task, noted in code).

**4. Files changed**
`laravel_backend/app/Http/Controllers/Api/AuthController.php` → `requestOtp()`

---

## C3 — Public invite acceptance with arbitrary user_id

**1. Root cause**
`acceptInvite()` was public and took a client-supplied `user_id`, then promoted
**that arbitrary existing user** to `MANAGER`. (It also didn't match the
client contract — Flutter sends `code/name/email/password` to register a new
manager, so the invite flow was effectively broken too.)

**2. Security impact** (🔴 Critical, OWASP A01)
With any valid unused invite code, an attacker could promote any `user_id` to
MANAGER under an owner — privilege escalation / team-scope account takeover,
with no authentication as that user.

**3. Applied fix**
Rewrote `acceptInvite()` to match the real client contract and remove the
attack surface:
- Validates `code, name, email (unique), password` — **no `user_id` accepted**.
- Verifies the invite code is valid + unused + unexpired.
- **Creates a brand-new MANAGER** account from the signup fields, scoped to the
  invite's `ownerId`; marks the invite used.
- Issues a Sanctum token so the new manager is logged in (same response shape
  as register/login the clients already expect).

This both closes the vulnerability (no arbitrary-id promotion) and fixes the
previously-mismatched invite flow.

**4. Files changed**
`laravel_backend/app/Http/Controllers/Api/AuthController.php` → `acceptInvite()`

---

## Verification Results

| Check | Result |
|-------|--------|
| `php -l` AuthController | ✅ No syntax errors |
| **Registration works** | ✅ FREELANCER signup → role `FREELANCER`; OWNER default works |
| **C1 escalation blocked** | ✅ `role:ADMIN` → HTTP 422 "selected role is invalid" |
| **OTP flow works** | ✅ `otp/request` → 200 (OTP stored), `otp/verify` wrong code → 422 |
| **C2 no leak** | ✅ `otp/request` response keys = `['message']` only; no `otp` field |
| **Invite flow works** | ✅ valid code → new MANAGER created, token issued, correct `ownerId` |
| **C3 attack blocked** | ✅ `{code, user_id:1}` → HTTP 422 (user_id ignored; name/email/password required) |
| **No permission regressions** | ✅ existing OWNER/admin login + role behavior unchanged |
| Test accounts cleaned | ✅ verification users removed; DB integrity preserved |

> Note on existing tests: the repo has no automated PHPUnit suite wired for
> these endpoints; verification was done via live API calls against the running
> server (results above). Recommend adding feature tests for these 3 flows.

---

## Result
- ✅ 3 Critical auth vulnerabilities fixed in a single file, minimal diffs
- ✅ Legitimate registration, OTP, and invite flows preserved (invite flow also repaired)
- ✅ No UI, no business-logic, no API-shape changes for legit clients
- ⏹️ **Stopped after C1–C3. H1, H2, Medium, Low NOT touched — awaiting approval.**
