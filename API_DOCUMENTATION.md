# ClickerPro — API Documentation

Base URL (dev): `http://localhost:5000`  ·  All routes are prefixed with `/api`.
Source of truth: `laravel_backend/routes/api.php` (166 route declarations).

## Conventions

- **Auth:** Laravel Sanctum bearer token. Send `Authorization: Bearer <token>`
  on protected routes. Obtain a token from `/api/auth/login` (or register).
- **Response envelope:** success responses are wrapped as `{ "data": ... }`.
  Lists may add `total` / `totalAmount`. Errors return `{ "message": "..." }`
  (validation errors add an `errors` map, HTTP 422).
- **Rate limits (middleware):** auth routes `throttle:6,1`; other public
  `throttle:30,1`; all protected `throttle:120,1` (per minute).
- **Permission tiers:** Public · Authenticated (`auth:sanctum`) · Admin
  (`auth:sanctum` + `admin` middleware, role === ADMIN).

---

## Route Count Summary (verified)

| Group | Middleware | Routes |
|-------|-----------|-------:|
| Public — auth | `throttle:6,1` | 7 |
| Public — other | `throttle:30,1` | 6 |
| Authenticated (non-admin) | `auth:sanctum` + `throttle:120,1` | 105 |
| Admin | `+ admin` prefix `admin` | 48 |
| **Total** | | **166** |

Verified: `grep -cE "Route::(get|post|patch|delete)" routes/api.php` = 166;
`php artisan route:list | grep -c "api/"` = 166.

---

## 1. Public — Auth (`throttle:6,1`, no token)

| Method | URI | Handler |
|--------|-----|---------|
| POST | `/api/auth/register` | AuthController@register |
| POST | `/api/auth/login` | AuthController@login |
| POST | `/api/auth/forgot` | AuthController@forgotPassword |
| POST | `/api/auth/reset` | AuthController@resetPassword |
| POST | `/api/auth/otp/request` | AuthController@requestOtp |
| POST | `/api/auth/otp/verify` | AuthController@verifyOtp |
| POST | `/api/auth/accept-invite` | AuthController@acceptInvite |

### POST /api/auth/register
- **Auth:** none.
- **Validation:** `name` required string≤255 · `email` required email unique ·
  `phone` nullable string≤30 · `password` required string≥6 ·
  `role` nullable in `OWNER,FREELANCER,BOTH` (ADMIN/MANAGER rejected).
- **Request:**
```json
{ "name": "Rafi Khan", "email": "rafi@example.com", "password": "secret123", "role": "OWNER" }
```
- **Response 201:**
```json
{ "data": { "token": "12|abc…", "user": { "id": 5, "name": "Rafi Khan", "email": "rafi@example.com", "role": "OWNER", "plan": "FREE", "publicToken": "uuid…" } } }
```

### POST /api/auth/login
- **Auth:** none. **Validation:** `email` required email · `password` required.
- **Request:** `{ "email": "owner@test.com", "password": "Test@1234" }`
- **Response 200:** `{ "data": { "token": "…", "user": { … } } }`
- **Errors:** 401 `{ "message": "Invalid credentials" }`; 403 if account disabled.

### POST /api/auth/forgot
- `email` required email. Always returns `{ "message": "ok" }` (no user
  enumeration). Stores a hashed reset token.

### POST /api/auth/reset
- `email` required email · `token` required string · `password` required ≥6.
- Token must match **and** be ≤60 minutes old, else 422
  `{ "message": "Invalid or expired token" }`.

### POST /api/auth/otp/request
- `email` required email · `purpose` required string. Returns `{ "message":"ok" }`
  (the OTP is **not** returned in the response; deliver out-of-band).

### POST /api/auth/otp/verify
- `email`, `code`, `purpose` all required. Returns 200 on match; 422 on
  invalid/expired; **429** after 5 failed attempts (request a new OTP).

### POST /api/auth/accept-invite
- `code` required · `name` required ≤255 · `email` required unique · `password`
  required ≥6. Creates a new **MANAGER** account scoped to the invite's owner and
  returns `{ "data": { "token", "user" } }`. Does **not** accept a `user_id`.

---

## 2. Public — Other (`throttle:30,1`, no token)

| Method | URI | Handler | Notes |
|--------|-----|---------|-------|
| GET | `/api/legal/privacy/{lang}` | LegalController@privacy | privacy text by language |
| GET | `/api/legal/terms/{lang}` | LegalController@terms | terms text by language |
| GET | `/api/public-booking/{token}` | PublicBookingController@show | studio + packages by public token |
| POST | `/api/public-booking/{token}` | PublicBookingController@store | submit a public booking request |
| POST | `/api/contact` | ContactController@store | `name`,`email`,`message` required; logs enquiry |
| POST | `/api/crash-reports` | CrashReportController@store | `error` required (+ optional stackTrace/breadcrumbs/platform) |

---

## 3. Authenticated (`auth:sanctum`) — non-admin

> All require `Authorization: Bearer <token>`. Most resources are **scoped to
> the current user** (`owner_id`); accessing another user's resource returns 403.

### Auth / Profile
| Method | URI | Handler | Notes |
|--------|-----|---------|-------|
| POST | `/api/auth/logout` | AuthController@logout | revokes current token |
| POST | `/api/auth/change-password` | AuthController@changePassword | `currentPassword`/`newPassword` (camel or snake); 422 on wrong current |
| GET | `/api/profile` | ProfileController@show | returns UserResource |
| PATCH | `/api/profile` | ProfileController@update | `name,phone,bio,business_name,avatar` (privilege fields ignored) |

### Bookings
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/bookings` | BookingController@index (filters: `status`,`search`,`limit`) |
| POST | `/api/bookings` | BookingController@store |
| GET | `/api/bookings/{id}` | BookingController@show |
| PATCH | `/api/bookings/{id}` | BookingController@update |
| PATCH | `/api/bookings/{id}/status` | BookingController@updateStatus |
| DELETE | `/api/bookings/{id}` | BookingController@destroy |

**POST/PATCH /api/bookings** validation (`BookingRequest`): on create `title` &
`date` required; all nullable on update. Fields: `title` string≤255 · `date` date
· `client_id` int exists · `package_id` int exists · `event_type` string≤100 ·
`venue` string≤255 · `shift` in `DAY,NIGHT,BOTH` · `status` string · `price`
numeric · `advance_paid` numeric · `due_amount` numeric · `notes`,`internal_notes`
string · `client_name` string≤255 · `client_phone` string≤30 (resolved to a client).
- **Request:**
```json
{ "title": "Nadia & Karim Wedding", "date": "2026-08-01", "shift": "BOTH",
  "client_name": "Nadia Rahman", "client_phone": "01700000000",
  "venue": "Gulshan Club", "price": 85000, "advance_paid": 30000 }
```
- **Response 201:**
```json
{ "data": { "id": 12, "title": "Nadia & Karim Wedding", "date": "2026-08-01",
  "shift": "BOTH", "status": "PENDING", "due_amount": 55000,
  "client_name": "Nadia Rahman", "client_phone": "01700000000" } }
```

### Assignments (booking sub-resource; owner-scoped → 403 if not owner)
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/bookings/{eventId}/assignments` | AssignmentController@index |
| POST | `/api/bookings/{eventId}/assignments` | AssignmentController@store |
| PATCH | `/api/bookings/{eventId}/assignments/{id}` | AssignmentController@update |
| DELETE | `/api/bookings/{eventId}/assignments/{id}` | AssignmentController@destroy |

POST validation: `user_id` required int exists · `role` nullable string≤100 ·
`payout` nullable numeric≥0 · `payout_paid` nullable bool · `notes` nullable.

### Clients
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/clients` | ClientController@index (filter: `search`) |
| POST | `/api/clients` | ClientController@store |
| GET | `/api/clients/{id}` | ClientController@show (incl. that client's bookings) |
| PATCH | `/api/clients/{id}` | ClientController@update |
| DELETE | `/api/clients/{id}` | ClientController@destroy |

POST/PATCH validation (`ClientRequest`): `name` required-on-create string≤255 ·
`phone` string≤30 · `email` email≤255 · `notes` string.

### Payments
| Method | URI | Handler | Notes |
|--------|-----|---------|-------|
| GET | `/api/payments` | PaymentController@index | filters `kind`,`method` |
| POST | `/api/payments` | PaymentController@store | 403 if event not owned |
| GET | `/api/payments/event/{eventId}` | PaymentController@byEvent | 403 if not owned |
| GET | `/api/payments/earnings` | PaymentController@earnings | sums by kind |

**POST /api/payments** validation: `event_id` required int exists · `amount`
required numeric≥0 · `kind` required in `ADVANCE,DUE,EXTRA,PAYOUT` · `method`
nullable in `CASH,BKASH,NAGAD,BANK,CARD,OTHER` · `note` nullable · `paid_at`
nullable date. Side effect: ADVANCE increments `advance_paid`, DUE decrements
`due_amount` (transactional, via PaymentService).
- **Request:** `{ "event_id": 12, "amount": 1000, "kind": "DUE", "method": "BKASH" }`
- **Response 201:** `{ "data": { "id": 40, "event_id": 12, "amount": "1000.00", "kind": "DUE", "method": "BKASH" } }`

### Invoices
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/invoices` | InvoiceController@index |
| POST | `/api/invoices` | InvoiceController@store (403 if event not owned) |
| GET | `/api/invoices/{id}` | InvoiceController@show (owner-scoped) |
| GET | `/api/invoices/event/{eventId}` | InvoiceController@byEvent |
| PATCH | `/api/invoices/{id}` | InvoiceController@update |

POST validation: `event_id` required exists · `subtotal` required numeric≥0 ·
`tax_rate`,`tax_amount` nullable numeric · `total` required numeric≥0 · `notes`
nullable · `language` nullable≤10 · `status` nullable in `DRAFT,SENT,PAID,OVERDUE`.

### Expenses
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/expenses` | ExpenseController@index (filter `event_id`) |
| POST | `/api/expenses` | ExpenseController@store |
| PATCH | `/api/expenses/{id}` | ExpenseController@update |
| DELETE | `/api/expenses/{id}` | ExpenseController@destroy |

POST validation: `title` required≤255 · `amount` required numeric≥0 ·
`event_id` nullable exists · `category` nullable≤100 · `note` nullable ·
`receipt_url` nullable · `date` nullable date.

### Gear & Rent
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/gear` | GearController@index |
| POST | `/api/gear` | GearController@store |
| PATCH | `/api/gear/{id}` | GearController@update |
| DELETE | `/api/gear/{id}` | GearController@destroy |
| GET | `/api/gear/{gearId}/rent` | RentController@index |
| GET | `/api/rent` | RentController@all |
| POST | `/api/rent` | RentController@store |

Gear POST: `name` required≤255 · `category` nullable≤100 · `serial_number`
nullable≤100 · `condition` nullable≤50 · `purchase_value` nullable numeric≥0 ·
`notes` nullable. Rent POST: `gear_item_id` required exists · `direction` required
in `IN,OUT` · `rented_to`,`amount`,`rented_at`,`returned_at`,`notes`.

### Petty Cash
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/petty-cash` | PettyCashController@index / store |
| PATCH / DELETE | `/api/petty-cash/{id}` | update / destroy |

POST: `title` required≤255 · `amount` required numeric≥0 · `category` nullable in
`transport,food,print,phone,misc` · `date` nullable date · `note` nullable.

### Follow-ups
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/followups` | FollowupController@index / store |
| PATCH / DELETE | `/api/followups/{id}` | update / destroy |

POST: `event_id` nullable exists · `type` nullable in `album,payment,feedback` ·
`scheduled_date` required date · `note` nullable.

### Freelancer tools
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/freelancer/blackouts` | blackouts / storeBlackout |
| DELETE | `/api/freelancer/blackouts/{id}` | destroyBlackout |
| GET / POST | `/api/freelancer/leaves` | leaves / storeLeave |
| PATCH / DELETE | `/api/freelancer/leaves/{id}` | updateLeave / destroyLeave |
| GET | `/api/freelancer/work-history` | workHistory |
| GET | `/api/freelancer/earnings` | earnings |

Blackout POST: `date` required date · `end_date` nullable · `reason` nullable≤255
· `recurrence` nullable in `none,weekly,monthly,yearly`. Leave POST:
`start_date`,`end_date` required date · `reason` required≤255 · `notes` nullable.

### Packages
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/packages` | PackageController@index / store |
| PATCH / DELETE | `/api/packages/{id}` | update / destroy |

POST: `name` required≤255 · `base_price` required numeric≥0 · `coverage_hours`
nullable int≥0 · `has_video`,`has_drone`,`has_album` nullable bool · `notes`.

### Team
| Method | URI | Handler | Notes |
|--------|-----|---------|-------|
| GET | `/api/team` | TeamController@members | alias of members |
| GET | `/api/team/invite` | TeamController@getInvite | latest active invite code |
| POST | `/api/team/invite` | TeamController@invite | generates a 7-day code |
| GET | `/api/team/members` | TeamController@members | users with ownerId = caller |
| PATCH | `/api/team/members/{userId}/permissions` | TeamController@updatePermissions | 403 unless member's ownerId === caller; `permissions` required array |

### Re-edits & Tasks (booking sub-resources, owner-scoped)
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/bookings/{eventId}/reedits` | ReEditController@index / store (`description` required) |
| PATCH | `/api/reedits/{id}` | ReEditController@update (`status` in PENDING/APPROVED/REJECTED) |
| GET | `/api/bookings/{eventId}/tasks` | TaskController@index |
| POST | `/api/bookings/{eventId}/tasks` | TaskController@upsert (`percentage` 0–100, `note`) |

### Delivery & Extra time
| Method | URI | Handler |
|--------|-----|---------|
| PATCH | `/api/bookings/{eventId}/delivery` | DeliveryController@update |
| POST | `/api/bookings/{eventId}/extra-time` | ExtraTimeController@store |

### Reports / Search
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/reports/summary` | ReportController@summary (revenue, counts, monthly) |
| GET | `/api/search?q=` | SearchController@search (global search) |

### Notifications & Broadcasts
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/notifications` | NotificationController@index |
| PATCH | `/api/notifications/{id}/read` | NotificationController@markRead |
| GET | `/api/broadcasts` | BroadcastController@index |
| POST | `/api/broadcasts/{id}/view` | BroadcastController@trackView |
| POST | `/api/broadcasts/{id}/click` | BroadcastController@trackClick |

### Chat
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/chat/groups` | ChatController@groups / createGroup |
| GET | `/api/chat/groups/{groupId}/messages` | ChatController@messages |
| POST | `/api/chat/groups/{groupId}/messages` | ChatController@sendMessage (`body`) |

### Support / FAQ
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/support` | SupportController@index / store (`subject`,`body`) |
| GET | `/api/support/{id}` | SupportController@show |
| GET | `/api/faqs` | FaqController@index |

### Waitlist / Reminders
| Method | URI | Handler |
|--------|-----|---------|
| GET / POST | `/api/waitlist` | WaitlistController@index / store |
| DELETE | `/api/waitlist/{id}` | WaitlistController@destroy |
| GET / POST | `/api/reminders` | ReminderController@index / store |
| DELETE | `/api/reminders/{id}` | ReminderController@destroy |

### Account / Activity / 2FA / Devices / Entitlements / Coupons / Files
| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/my-activity` | AuditLogController@mine (current user's audit trail) |
| GET | `/api/security/2fa/status` | SecurityController@twoFaStatus |
| POST | `/api/security/2fa/setup` | SecurityController@twoFaSetup (returns secret + QR) |
| POST | `/api/security/2fa/verify` | SecurityController@twoFaVerify (`token`) |
| POST | `/api/security/2fa/disable` | SecurityController@twoFaDisable |
| POST | `/api/devices` | DeviceTokenController@register (`token`) |
| GET | `/api/entitlements/{key}` | EntitlementController@check |
| POST | `/api/coupons/apply` | CouponController@apply |
| POST | `/api/account/delete-request` | AccountController@requestDelete |
| POST | `/api/account/cancel-delete` | AccountController@cancelDelete |
| POST | `/api/files/upload` | FileController@upload (`file`, mimes: jpg,jpeg,png,webp,gif,pdf, max 10 MB) |
| DELETE | `/api/files` | FileController@destroy (`path`) |

---

## 4. Admin (`auth:sanctum` + `admin` middleware, prefix `/api/admin`)

> All require an ADMIN-role token; non-admins receive 403 from `AdminMiddleware`.

| Method | URI | Handler |
|--------|-----|---------|
| GET | `/api/admin/stats` | AdminController@stats (cached 60s) |
| GET | `/api/admin/analytics` | AdminController@analytics (cached 60s) |
| GET | `/api/admin/users` | AdminController@users (filters `search`,`role`) |
| GET | `/api/admin/users/{id}` | AdminController@userDetail |
| PATCH | `/api/admin/users/{id}` | AdminController@updateUser |
| PATCH | `/api/admin/users/{id}/role` | AdminController@setRole (`role` enum) |
| PATCH | `/api/admin/users/{id}/plan` | AdminController@setPlan (`plan` FREE/PRO) |
| PATCH | `/api/admin/users/{id}/suspend` | AdminController@setSuspend (`suspended` bool) |
| GET | `/api/admin/export` · `/export/{file}` | AdminController@exportCsv (`type`/filename) |
| GET | `/api/admin/bookings` | AdminController@bookings (all studios) |
| GET | `/api/admin/payments` | AdminController@payments (all studios) |
| GET | `/api/admin/files` | FileController@adminIndex |
| DELETE | `/api/admin/files/{name}` | FileController@adminDestroy |
| GET/POST | `/api/admin/broadcasts` | BroadcastController@adminIndex / adminStore |
| PATCH/DELETE | `/api/admin/broadcasts/{id}` | adminUpdate / adminDestroy |
| GET | `/api/admin/support` · `/tickets` | SupportController@adminIndex |
| PATCH | `/api/admin/support/{id}/reply` · `/tickets/{id}` | adminReply |
| GET/POST | `/api/admin/faqs` | FaqController@adminIndex / adminStore |
| PATCH/DELETE | `/api/admin/faqs/{id}` | adminUpdate / adminDestroy |
| GET/POST | `/api/admin/coupons` | CouponController@index / store |
| PATCH/DELETE | `/api/admin/coupons/{id}` | update / destroy |
| GET | `/api/admin/audit-logs` · `/audit` | AuditLogController@index |
| GET | `/api/admin/security/login-activity` | SecurityController@loginActivity |
| GET | `/api/admin/security/blocked-ips` | SecurityController@blockedIps |
| POST | `/api/admin/security/block-ip` · `/blocked-ips` | blockIp (`ip`,`reason`) |
| DELETE | `/api/admin/security/block-ip/{ip}` · `/blocked-ips/{ip}` | unblockIp |
| GET/POST/VERIFY/DISABLE | `/api/admin/security/2fa/*` | SecurityController twoFa* |
| GET/POST | `/api/admin/settings` | SettingsController@index / update |
| GET | `/api/admin/feature-flags` · `/features` | FeatureFlagController@index |
| PATCH | `/api/admin/feature-flags/{id}` · `/features/{key}` | update |

**GET /api/admin/stats — example response:**
```json
{ "data": { "totalUsers": 3, "owners": 2, "freelancers": 0, "admins": 1,
  "totalBookings": 7, "totalClients": 8, "activeBroadcasts": 2,
  "openTickets": 0, "totalRevenueMinor": 12700000 } }
```

---

## Verification Summary

- **Route file declarations** (`grep -cE "Route::(get|post|patch|delete)"`): **166**
- **`php artisan route:list | grep -c api/`**: **166** ✅ match
- **Group totals:** auth 7 + public 6 + authenticated 105 + admin 48 = **166** ✅
- Every endpoint above is copied from `routes/api.php`; validation rules are
  quoted from the corresponding `validate([...])` / FormRequest in each
  controller. No endpoints were invented or inferred.
