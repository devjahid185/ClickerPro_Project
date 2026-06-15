# Security Fix Report — M1 (Medium)

> Date: 2026-06-08
> Approved scope: **M1 only** — excessive user data in auth responses.
> Approach: explicit-allowlist `UserResource` serializer.
> Decision: `public_booking_token` is **kept** in the response (it is the user's
> OWN booking link, which the Settings screen displays) — exposing a user's own
> token to that same user is not a leak. The fix instead removes truly internal
> fields and prevents future columns from auto-leaking.

---

## Root cause
`register`, `login`, `acceptInvite`, and `profile show/update` returned the raw
`User` Eloquent model. `toArray()` on a model serializes **every column** (and
any column added later), exposing internal-only fields such as
`manager_permissions`, `ip_address`, `user_agent`, `last_activity`, and
`email_verified_at`. (`password`/`totp_secret` were already in `$hidden`.)

## Security impact (🟡 Medium, OWASP A01 / excessive data exposure)
Clients received internal authorization/tracking data they don't need, and any
future sensitive column would be exposed automatically with no code change.

## Fix applied
Created `app/Http/Resources/UserResource.php` — an explicit **allowlist**
serializer returning only the fields the clients use:
`id, name, email, phone, role, plan, is_active, business_name (+businessName),
bio, avatar, public_booking_token (+publicToken/bookingToken), totp_enabled,
created_at`.

- Internal fields (`manager_permissions`, `ip_address`, `user_agent`,
  `last_activity`, `email_verified_at`) are **no longer returned**.
- `password` / `totp_secret` remain excluded (never listed; model `$hidden`).
- camelCase aliases included so the web app (camelCase) and Flutter app
  (snake_case) both keep working from the same payload — **no client change**.
- Response envelope unchanged: still `{ data: { token, user: {...} } }` /
  `{ data: {...} }`; the resource is embedded as an array, so there's no
  double-`data` wrapping.

Applied at every auth/profile response:
- `AuthController::register`, `login`, `acceptInvite`
- `ProfileController::show`, `update`

## Files changed
- `app/Http/Resources/UserResource.php` (new)
- `app/Http/Controllers/Api/AuthController.php` (register, login, acceptInvite)
- `app/Http/Controllers/Api/ProfileController.php` (show, update)

## Verification Results
| Check | Result |
|-------|--------|
| `php -l` (all changed) | ✅ No syntax errors |
| **Login works** | ✅ token + user returned |
| **Registration works** | ✅ token + user returned |
| **Profile show works** | ✅ allowlisted user returned |
| **Profile update works** | ✅ bio updated; returns resource |
| **Token generation works** | ✅ present in all auth responses |
| **Required frontend fields present** | ✅ id, name, email, role, plan, phone, businessName, bio, avatar, publicToken |
| **public_booking_token usable by Settings** | ✅ present (own token, intended) |
| **Internal fields removed** | ✅ no `manager_permissions`/`ip_address`/`user_agent`/`last_activity` |
| **password/totp_secret** | ✅ never present |
| **M2 still holds** | ✅ profile PATCH with `role` injection → role unchanged |
| No regressions | ✅ owner/admin flows intact; test accounts cleaned |

## Result
- ✅ M1 fixed via allowlist UserResource; internal data no longer exposed
- ✅ All auth/profile flows + token generation preserved; clients unchanged
- ✅ Settings public-booking-link feature preserved (own token retained)
