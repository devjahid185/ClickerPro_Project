# Bug Fix — Phase 0 (Critical: Mobile ⇄ Laravel Contract + Security)

> Date: 2026-06-10
> Scope: the Critical/High findings from the 2026-06-10 production audit that
> block real-device testing against the live backend (api.deyalghori.com).
> Verified: `flutter analyze lib` → 0 issues · `flutter test` → 132/132 pass.

---

## Root cause recap

The Flutter app's core API layer was written against the OLD Node backend
contract (flat camelCase JSON, string ids, `{items:[…]}` lists). The Laravel
backend wraps everything in `{data: …}` with snake_case columns, integer ids
and SCREAMING_SNAKE enums. Result: login "succeeded" into a fake offline demo
session, lists silently came back empty, and a synced booking-create could
duplicate rows server-side on retry.

## What changed

### New
| File | Purpose |
|------|---------|
| `clicker_pro/lib/features/bookings/data/server_wire.dart` | ALL Laravel⇄Flutter shape translation in one place: `{data}` unwrap, snake↔camel, id coercion, enum maps (`PENDING`↔`pending`, `DAY`↔`day`, …), `bookingFromServer/ToServer`, `clientFromServer/ToServer`, `statusEntryFromServer`. Server responses are mapped **with the local copy as fallback** so local ids and locally-only fields survive sync. |

### Fixed — Flutter
| File | Fix |
|------|-----|
| `auth/data/auth_api.dart` | C1: unwrap `{data:{token,user}}` on login/register/invite/social; profile `{data:user}`; register sends role UPPERCASE (Laravel rejects lowercase); OTP request/verify send `email`; reset sends `password`+`email`; account delete/cancel/export tolerate Laravel's actual shapes. Bad 2xx shapes now raise a descriptive ApiException instead of a TypeError. |
| `auth/data/auth_repository_impl.dart` | C2: offline demo session + demo OTP `123456` now **hard-disabled when `ENVIRONMENT=production`** — network failures surface as real errors instead of a fake OWNER login. verifyOtp handles Laravel's token-less `{message:ok}` response. |
| `bookings/data/booking_api.dart` | C1: list/create/patch/detail/status all speak the Laravel contract; status transition now **PATCH** `/bookings/:id/status` with `{status,note}` (was POST → 405); timeline entry synthesized locally. |
| `bookings/data/client_api.dart` | C1: `{data}` unwrap; `/clients/search` (nonexistent route, 500'd) → `/clients?search=`; create/patch send only the columns `ClientRequest` validates. |
| `bookings/data/status_api.dart` | C1: reads `status_histories` from the Laravel payload. |
| `core/sync/bookings_outbox_dispatcher.dart` | C3: parse/programming errors now park the row as `manual_retry` instead of blind-retrying (a successful-but-unparsed create was re-POSTed up to 5×, creating up to 5 duplicate bookings server-side). Raw SocketException/Timeout still retry. |
| `core/db/daos/bookings_dao.dart`, `clients_dao.dart` | New `getByRemoteId` for pull-merge. |
| `bookings/data/booking_repository_impl.dart`, `client_repository_impl.dart` | Pulled server rows now **merge into the existing local row by `remoteId`** (local id + locally-only fields preserved, pending local edits win) instead of inserting duplicates under the server id. |
| `profile/domain/user_model.dart` | Accepts Laravel's `avatar` / `business_name` / `owner_id` spellings. |
| `auth/presentation/login_screen.dart` | M1: error message now by status code — 401 "ইমেইল বা পাসওয়ার্ড ভুল", **429 "১ মিনিট অপেক্ষা করুন"**, 403 disabled, 0 network. H1: Google/Apple buttons hidden behind `kSocialLoginEnabled=false` (backend has no `/auth/google|apple` routes — they always 404'd). |

### Fixed — Laravel (needs server `git pull` to go live)
| File | Fix |
|------|-----|
| `app/Http/Controllers/Api/ClientController.php` | `show()` filtered bookings by `events.client_name` — a column that doesn't exist → 500 on every client-detail call (web app too). Now filters by `client_id`. |

## Knowingly deferred (Phase 1)
- assignment / payment / package / re-edit / task-progress / gear / team /
  reports / search / rent API files still speak the old contract. They now
  fail SAFELY (manual-retry, no duplicates) but don't sync. Each needs the
  same server_wire treatment + its Laravel field map.
- Laravel `events` schema doesn't persist startTime/endTime, bride/groom,
  coverage hours, drive link, etc. — those fields stay device-local until the
  backend adds columns. The merge layer protects them from being wiped.
- `/api/auth/google`, `/api/auth/apple`, `/api/profile/role`,
  `/api/account/export` backend routes don't exist yet.
- Password-reset end-to-end needs a real mail driver (token is emailed).
