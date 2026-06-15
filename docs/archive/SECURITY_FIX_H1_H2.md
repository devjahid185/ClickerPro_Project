# Security Fix Report — H1, H2 (High)

> Date: 2026-06-08
> Approved scope: **H1 + H2 only**. Smallest safe change; preserve business
> logic, user flows, and API compatibility. (Medium/Low NOT touched.)

---

## H1 — Missing authorization on team permission updates (IDOR)

**1. Root cause**
`TeamController::updatePermissions($userId)` looked up any user by id and
overwrote their `manager_permissions` with **no check** that the target was
actually a member of the caller's team.

**2. Security impact** (🟠 High, OWASP A01)
Any authenticated user could PATCH `/api/team/members/{anyId}/permissions` and
grant elevated permissions (`can_see_finance`, `can_manage_team`, …) on
arbitrary accounts — privilege escalation and finance-data exposure.

**3. Applied fix**
Added an ownership guard that mirrors how `members()` already scopes the team
list: the target member's `manager_permissions.ownerId` must equal the caller's
id, else `403`. Comparison is done as integers (the stored ownerId may be an int
or a numeric string). No change to the update logic itself or the response shape.

```php
$ownerId = $request->user()->id;
$memberOwnerId = $member->manager_permissions['ownerId'] ?? null;
if ($memberOwnerId === null || (int) $memberOwnerId !== (int) $ownerId) {
    return response()->json(['message' => 'Forbidden'], 403);
}
```

**4. Files changed**
`laravel_backend/app/Http/Controllers/Api/TeamController.php` → `updatePermissions()`

---

## H2 — Password-reset token never expired

**1. Root cause**
`AuthController::resetPassword` verified the hashed token matched but never
checked its age. The `password_reset_tokens` row (and its token) stayed valid
indefinitely.

**2. Security impact** (🟠 High, OWASP A07)
A leaked or old reset token could be redeemed at any later time to take over an
account — no time window limiting exposure.

**3. Applied fix**
After the hash check, reject tokens older than **60 minutes** using the stored
`created_at` (which `forgotPassword` already sets to `now()`), and delete the
stale row. Valid (fresh) tokens work exactly as before. API shape unchanged
(same 422 message on rejection).

```php
$createdAt = $record->created_at ? Carbon::parse($record->created_at) : null;
if (!$createdAt || $createdAt->lt(now()->subMinutes(60))) {
    DB::table('password_reset_tokens')->where('email', $data['email'])->delete();
    return response()->json(['message' => 'Invalid or expired token'], 422);
}
```

**4. Files changed**
`laravel_backend/app/Http/Controllers/Api/AuthController.php` → `resetPassword()`

---

## Verification Results

| Check | Result |
|-------|--------|
| `php -l` (both controllers) | ✅ No syntax errors |
| **Permission update flow works** | ✅ owner editing own team member → HTTP 200 |
| **Team management works** | ✅ invite → create manager → list/edit unchanged |
| **H1 IDOR blocked (foreign editor)** | ✅ different user editing owner's member → 403 |
| **H1 arbitrary target blocked** | ✅ editing a non-team user → 403 |
| **Password reset works (valid)** | ✅ fresh token → HTTP 200 |
| **H2 expired token rejected** | ✅ 2-hour-old token → HTTP 422 "Invalid or expired token" |
| **forgotPassword unchanged** | ✅ HTTP 200 |
| No permission/flow regressions | ✅ legit owner/admin/manager paths intact |
| Test accounts cleaned | ✅ verification manager removed |

> As before, the repo has no automated PHPUnit suite for these endpoints;
> verification was via live API calls against the running server (results above).

---

## Remaining Security Findings (NOT fixed — awaiting approval)

From `SECURITY_AUDIT.md`:

| # | Finding | Severity |
|---|---------|----------|
| M1 | `register`/`login` return full user incl. `public_booking_token`, `manager_permissions` | 🟡 Medium |
| M2 | Mass-assignment: `role`,`plan`,`is_active`,`manager_permissions` in User `$fillable` | 🟡 Medium |
| M3 | Web/Admin JWT in `localStorage` (XSS-exfiltratable; mitigated by CSP/TTL) | 🟡 Medium |
| M4 | OTP verify has no per-account attempt cap (only IP throttle) | 🟡 Medium |
| L1 | 2FA `secret` returned in setup response (expected; note) | 🟢 Low |
| L2 | `APP_DEBUG=true`/`APP_ENV=local` in `.env` (deploy config) | 🟢 Low |
| — | A06: run `composer audit` / `npm audit` / `flutter pub outdated` (dependency CVEs) | follow-up |

**All Critical (C1–C3) and High (H1–H2) findings are now fixed.**

---

## Result
- ✅ H1 + H2 fixed with minimal diffs in 2 files
- ✅ Team management, permission update, and password reset flows preserved
- ✅ IDOR closed; expired reset tokens rejected; valid ones still work
- ✅ No business-logic / API-shape changes for legit clients
- ⏹️ **Stopped after H1, H2. Medium/Low remain open — awaiting approval.**
