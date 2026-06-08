# ClickerPro — Database Schema

PostgreSQL schema, derived from `laravel_backend/database/migrations/` (40
migrations). All Laravel `foreignId()->constrained()` columns create a foreign
key **and an index** automatically; cascade behavior is noted per column.

> Conventions: every table has `id` (bigint PK) and `created_at`/`updated_at`
> (`timestamps()`) unless noted. `softDeletes()` adds a nullable `deleted_at`.
> Money columns are `decimal(10,2)` in major units (Taka).

---

## Core Domain Tables

### users
| Column | Type | Notes |
|--------|------|-------|
| id | bigint PK | |
| name | string | |
| email | string | **unique** |
| phone | string nullable | |
| password | string | bcrypt-hashed |
| role | string | default `OWNER` (OWNER/FREELANCER/BOTH/MANAGER/ADMIN) |
| plan | string | default `FREE` (FREE/PRO) |
| business_name | string nullable | |
| bio | string nullable | |
| avatar | string nullable | |
| is_active | boolean | default true |
| manager_permissions | json nullable | team scope (`{ownerId, permissions}`) |
| public_booking_token | string nullable | **unique** (public booking link) |
| totp_secret | string nullable | hidden |
| totp_enabled | boolean | default false |
| email_verified_at | timestamp nullable | |
| remember_token, deleted_at | | rememberToken + softDeletes |

### clients
| Column | Type | Notes |
|--------|------|-------|
| owner_id | FK→users | **cascade on delete**, indexed |
| name | string | |
| phone, email | string nullable | |
| notes | text nullable | |
| deleted_at | | softDeletes |

### events (bookings)
| Column | Type | Notes |
|--------|------|-------|
| owner_id | FK→users | cascade delete, indexed |
| client_id | FK→clients nullable | null on delete |
| package_id | FK→packages nullable | null on delete |
| title | string | |
| event_type | string nullable | |
| date | date | |
| venue | string nullable | |
| shift | string | default `DAY` (DAY/NIGHT/BOTH) |
| status | string | default `PENDING` |
| price | decimal(10,2) nullable | |
| advance_paid | decimal(10,2) | default 0 |
| due_amount | decimal(10,2) | default 0 |
| notes, internal_notes | text nullable | |
| delivered_at, completed_at | timestamp nullable | |
| sync_status | string | default `SYNCED` (offline sync) |
| remote_rev | integer | default 0 |
| deleted_at | | softDeletes |

**Extra indexes** (performance migration): `events_owner_date_idx (owner_id,
date)`, `events_owner_status_idx (owner_id, status)`.

### packages
| Column | Type | Notes |
|--------|------|-------|
| owner_id | FK→users | cascade delete |
| name | string | |
| base_price | decimal(10,2) | |
| coverage_hours | integer nullable | |
| has_video, has_drone, has_album | boolean | default false |
| notes | text nullable | |

### payments
| Column | Type | Notes |
|--------|------|-------|
| event_id | FK→events | cascade delete, indexed |
| recorded_by | FK→users | cascade delete |
| amount | decimal(10,2) | |
| kind | string | ADVANCE/DUE/EXTRA/PAYOUT |
| method | string | default `CASH` |
| note | text nullable | |
| paid_at | timestamp nullable | |

**Extra index:** `payments_created_at_idx (created_at)`.

### invoices
| Column | Type | Notes |
|--------|------|-------|
| event_id | FK→events | **unique** (one invoice per event), cascade |
| owner_id | FK→users | cascade delete |
| status | string | default `DRAFT` (DRAFT/SENT/PAID/OVERDUE) |
| subtotal | decimal(10,2) | |
| tax_rate | decimal(5,2) | default 0 |
| tax_amount | decimal(10,2) | default 0 |
| total | decimal(10,2) | |
| notes | text nullable | |
| language | string | default `en` |
| pdf_path | string nullable | |
| sent_at, paid_at | timestamp nullable | |

### assignments
event_id FK→events (cascade) · user_id FK→users (cascade) · role string nullable
· payout decimal(10,2) nullable · payout_paid boolean default false · notes text.

### expenses
owner_id FK→users (cascade) · event_id FK→events nullable (null on delete) ·
title string · amount decimal(10,2) · category string nullable · note text ·
receipt_url string nullable · date date.

### gear_items
owner_id FK→users (cascade) · name string · category string nullable ·
serial_number string nullable · condition string default `GOOD` ·
purchase_value decimal(10,2) nullable · notes text · is_available boolean default true.

### rent_records
gear_item_id FK→gear_items (cascade) · owner_id FK→users (cascade) ·
direction string (IN/OUT) · rented_to string · amount decimal(10,2) ·
rented_at timestamp · returned_at timestamp nullable · notes text.

### task_progresses
event_id FK→events (cascade) · user_id FK→users (cascade) · percentage integer
default 0 · note text.

### status_histories
event_id FK→events (cascade) · changed_by FK→users (cascade) ·
from_status string nullable · to_status string · note text.

### re_edit_requests
event_id FK→events (cascade) · requested_by FK→users (cascade) · description text
· status string default `PENDING` · admin_note text nullable.

### followups
owner_id FK→users (cascade) · event_id FK→events nullable (null on delete) ·
type string default `payment` (album/payment/feedback) · scheduled_date date ·
completed boolean default false · note text.

### petty_cash_entries
owner_id FK→users (cascade) · title string · category string default `misc`
(transport/food/print/phone/misc) · amount decimal(10,2) · date date · note text.

### blackout_dates (freelancer availability)
freelancer_id FK→users (cascade) · date date · end_date date nullable ·
reason string nullable · recurrence string default `none`
(none/weekly/monthly/yearly).

### leave_requests
freelancer_id FK→users (cascade) · owner_id FK→users nullable (null on delete) ·
start_date date · end_date date · reason string · notes text · status string
default `PENDING` (PENDING/APPROVED/REJECTED).

---

## Engagement / Support Tables

| Table | Key columns |
|-------|-------------|
| broadcasts | created_by FK→users · title · body · target_role · is_active · scheduled_at · view_count · click_count |
| chat_groups | (group container) |
| chat_messages | group + sender + body |
| support_tickets | user + subject + body + status (+ admin reply) |
| faqs | question + answer + category |
| reminders | owner + type + message + event_id + remind_at |
| waitlists | owner + client info + preferred date |
| coupons | code · type · value · max_uses · uses · expires_at · is_active |
| feature_flags | key · label · requires_pro · is_enabled |
| app_settings | platform key/value settings |
| device_tokens | user + FCM token |
| crash_reports | user_id nullable · error · stack_trace · breadcrumbs(json) · platform · app_version |

---

## Auth / Security Tables

| Table | Key columns |
|-------|-------------|
| otp_codes | user_id FK→users · code · purpose · expires_at · used · **attempts** (unsignedSmallInteger, default 0) |
| team_invite_codes | owner_id FK→users · code · used_by FK→users · used_at · expires_at |
| login_activities | email · ip · user_agent · success |
| blocked_ips | ip · reason · blocked_at |
| audit_logs | action · entity · entity_id · before(json) · after(json) · ip |
| password_reset_tokens | email · token(hashed) · created_at (60-min expiry enforced in code) |
| personal_access_tokens | Sanctum tokens (7-day expiration via `config/sanctum.php`) |

---

## Framework Tables
`cache`, `jobs`, `sessions` — Laravel's database cache/queue/session stores
(`CACHE_STORE=database`, `QUEUE_CONNECTION=database`, `SESSION_DRIVER=database`).

---

## Relationships (from Eloquent models)

**User** hasMany: events (owner_id), clients, payments(recorded_by), gear_items,
expenses, packages, broadcasts, etc.

**Event** (`app/Models/Event.php`):
- belongsTo `owner` (User), `client`, `package`
- hasMany `assignments`, `payments`, `statusHistories`, `reEditRequests`, tasks
- hasOne `invoice`

**Payment** belongsTo `event`, `recordedBy` (User).
**Invoice** belongsTo `event` (unique), `owner`.
**Assignment / TaskProgress / StatusHistory / ReEditRequest** belongsTo `event` + a User.
**Client / Package / GearItem / Expense / Followup / PettyCashEntry** belongsTo `owner`.
**RentRecord** belongsTo `gearItem`, `owner`.
**BlackoutDate / LeaveRequest** belongsTo `freelancer` (User).

---

## Constraints & Integrity Summary

- **Foreign keys:** all `owner_id`/`event_id`/`client_id`/`user_id`/etc. are FKs
  with `constrained()` → auto-indexed.
- **Cascade deletes:** child rows (payments, assignments, tasks, status
  histories, etc.) cascade when their event/user is deleted.
- **Null-on-delete:** `events.client_id`, `events.package_id`, `expenses.event_id`,
  `followups.event_id`, `leave_requests.owner_id` set null when the parent is removed.
- **Unique:** `users.email`, `users.public_booking_token`, `invoices.event_id`.
- **Soft deletes:** users, clients, events (recoverable; `deleted_at`).
- **App-level constraints:** booking `shift`/`status`, payment `kind`/`method`,
  package booleans, etc. are validated at the API layer (Form Requests /
  `validate()` enums) rather than DB CHECK constraints.

---

## Verification

- Tables enumerated from the 40 files in `database/migrations/` (40 = 38 domain
  tables + framework cache/jobs/sessions/etc. + 2 alter migrations:
  `add_performance_indexes`, `add_attempts_to_otp_codes`).
- Column types, defaults, FK cascade rules, and unique constraints are quoted
  from the migration `Schema::create`/`Schema::table` definitions.
- Relationships taken from the `app/Models/*.php` relation methods.
