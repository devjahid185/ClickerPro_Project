 # Implementation Plan: Bookings Module

## Overview

Convert the Feature Design into a series of prompts for a code-generation LLM that will implement each step with incremental progress. Make sure that each prompt builds on the previous prompts, and ends with wiring things together. There should be no hanging or orphaned code that isn't integrated into a previous step. Focus ONLY on tasks that involve writing, modifying, or testing code.

This plan converts the Bookings Module design into incremental, PR-sized Flutter + Node.js tasks that build on the Foundation MVP runtime. Implementation language is **Dart / Flutter** for the client (already established) and **Node.js + Prisma 5** for the backend (already established). The plan is wave-scheduled: tasks within the same wave are independent and can be parallelized; later waves depend on earlier waves. Every task references its requirements clauses for traceability.

Property-based tests use `glados` (added as a dev dependency in Wave 0). The 12 design Correctness Properties each map to a dedicated optional `*` test sub-task close to the implementation it validates.

Tasks marked with `*` are optional test sub-tasks; they may be skipped for a faster MVP but are strongly recommended (especially the property tests for `BookingStatusMachine`, role-scoped visibility, offline-write durability, and serializer round-trip).

---

## Tasks

### 0. Project skeleton & dependencies

- [x] 0.1 Add `glados` and (if missing) `url_launcher` to `pubspec.yaml`
  - `dev_dependencies: glados: ^1.1.7`
  - `dependencies: url_launcher: ^6.3.0` (only if not already present — used to open Drive links from `BookingDetailScreen`)
  - Run `flutter pub get`; expected: zero conflicts with Foundation MVP deps
  - _Requirements: 5.9, all property tests_

- [x] 0.2 Create `core/booking_status/`, `features/bookings/{data,domain,application,presentation/widgets,presentation/dialogs}`, and `features/public_booking/{data,domain,application,presentation}` folder skeletons under `lib/`
  - Add `_placeholder.dart` stubs in each empty folder to commit the structure
  - _Requirements: 1.0, 2.0, 4.0, 5.0, 6.0_

- [x] 0.3 Extend `core/navigation/route_names.dart` with bookings routes
  - Add: `calendar`, `bookingNew`, `bookingEdit`, `bookingDetail`, `reEditRequests`, `publicBooking`, `publicBookingSuccess`, `pendingPublicBookings`
  - Keep existing `bookings` constant unchanged
  - _Requirements: 1.9, 1.14, 4.5, 4.7, 6.7_

---

### 1. Drift schema additions (v1 → v2)

- [x] 1.1 Create the nine new Drift tables under `core/db/tables/`
  - `bookings_table.dart`, `clients_table.dart`, `assignments_table.dart`, `payments_table.dart`, `packages_table.dart`, `status_history_table.dart`, `re_edit_requests_table.dart`, `task_progress_table.dart`, `public_booking_requests_table.dart` exactly per design "Drift Schema Additions" section
  - Include `pending`, `updatedAt`, `remoteId` columns where the schema specifies them
  - Add unique key `(studioId, phone)` on `ClientsTable`; unique key `(bookingId, round)` on `ReEditRequestsTable`; composite primary key `(bookingId, userId)` on `TaskProgressTable`
  - _Requirements: 2.3, 6.1–6.8, 7.2, 8.3, 10.1, 10.2, 13.2_

- [x] 1.2 Extend `core/db/app_database.dart` `@DriftDatabase` table list AND bump `schemaVersion` from 1 → 2
  - Add a `MigrationStrategy.onUpgrade` handler that calls `m.createAll()` for the new tables when migrating from v1 to v2
  - Run `dart run build_runner build --delete-conflicting-outputs`; commit the regenerated `app_database.g.dart`
  - _Requirements: 10.1, 13.1_

- [x] 1.3 Create the nine DAOs under `core/db/daos/`
  - `bookings_dao.dart` — `watchList(filter, policy, currentUserId, page)`, `watchById`, `watchMonth(year, month, policy, currentUserId)`, `upsert`, `markPending`, `markSynced(remoteId, updatedAt)`, `delete`
  - `clients_dao.dart` — `watchById`, `searchByPhone(prefix)`, `getByPhone`, `upsert`
  - `assignments_dao.dart` — `watchByBooking`, `upsert`, `delete`
  - `payments_dao.dart` — `watchByBooking`, `upsert`, `delete`, `aggregateForBooking(bookingId)` (returns `(advance, due, extra, total)`)
  - `packages_dao.dart` — `watchAll`, `upsert`, `delete`
  - `status_history_dao.dart` — `watchByBooking`, `append`, `markSynced(remoteId)`, `deletePendingForBooking(bookingId, fromStatus, toStatus)` (used only by 409 reconciliation)
  - `re_edit_requests_dao.dart` — `watchByBooking`, `nextRoundFor(bookingId)`, `upsert`, `delete`
  - `task_progress_dao.dart` — `watchByBooking`, `watchOwn`, `upsert`
  - `public_booking_requests_dao.dart` — `watchPending`, `upsertPending`, `removeById`
  - Re-run `build_runner build` if any `@DriftAccessor` is added
  - _Requirements: 1.1, 1.4, 4.2, 5.1, 7.2, 8.3, 9.1, 10.1_

- [x] 1.4 Unit tests for each DAO using in-memory Drift (`NativeDatabase.memory()`)
  - Insert + watch emits + update + delete round-trip per DAO
  - `bookings_dao.watchList` returns role-scoped subset for fixed fixtures
  - `payments_dao.aggregateForBooking` returns `(advance + due + extra) == total` invariant
  - `re_edit_requests_dao.nextRoundFor` returns `max(round) + 1` or `1` when none exist
  - _Requirements: 1.1, 7.2, 10.1_

---

### 2. Pure helpers: BookingStatusMachine + booking_format

- [x] 2.1 Implement `core/booking_status/booking_status.dart`
  - `enum BookingStatus { pending, confirmed, inProgress, shotComplete, delivered, completed, cancelled }` with `fromString`, `name`, and a `displayName(BuildContext)` that delegates to ARB
  - _Requirements: 1.13, 3.1–3.3_

- [x] 2.2 Implement `core/booking_status/booking_status_machine.dart`
  - Pure functions exactly per design "Booking Status Machine" section: `_forward` map, `_cancellableFrom` set, `isAllowedTransition(from, to)`, `canRoleApply(role, from, to)`, `canTransition(role, from, to)`, `nextForward(from)`
  - No imports of `flutter_riverpod`, `Drift`, or any I/O — fully pure
  - _Requirements: 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7_

- [x] 2.3 Extend `core/format/` with `booking_format.dart`
  - `BookingFormat.money(amount, lang, bnNumerals, currencySymbol)`, `BookingFormat.percent(p, lang, bnNumerals)`, `BookingFormat.dateTime(dt, lang)`, `BookingFormat.relative(dt, lang, now?)` exactly per design "Format Helper Extensions" section
  - Reuse the Foundation MVP `formatNumber` helper for digit substitution (do NOT duplicate the substitution loop)
  - _Requirements: 1.11, 4.8, 5.10, 7.9, 8.6, 9.2, 9.6, 12.4_

- [x] 2.4 Property test: `BookingStatusMachine` exhaustive soundness (Property 1)
  - **Property 1: BookingStatusMachine soundness** — exhaustive over the cartesian product `BookingStatus × BookingStatus × UserRole`; assert `canTransition(role, from, to)` matches the static predicate `(_forward[from] == to OR (to == cancelled AND from IN _cancellableFrom)) AND (role != freelancer) AND NOT (to == cancelled AND role == manager)`
  - **Validates: Requirements 3.1, 3.2, 3.3, 3.4, 3.5, 3.6, 3.7**
  - Use `glados` with `Generator.union([forward, cancel, invalid])` over the BookingStatus enum × UserRole enum
  - _Requirements: 3.1–3.7_

- [x] 2.5 Property test: `BookingFormat` Bengali numerals coverage (Property 12 — booking-side)
  - **Property 12: Bengali numerals coverage on bookings** — for any non-negative integer `n` and any non-negative real `m`, the strings produced by `BookingFormat.money(m, lang: 'bn', bnNumerals: true)`, `BookingFormat.percent(n, lang: 'bn', bnNumerals: true)`, and `BookingFormat.dateTime(...)` contain digits exclusively in U+09E6–U+09EF and contain zero ASCII digits in their digit positions
  - **Validates: Requirements 1.11, 4.8, 5.10, 7.9, 8.6, 9.6, 12.4**
  - _Requirements: 12.4_

---

### 3. Domain models

- [x] 3.1 Create domain enums and value objects under `features/bookings/domain/`
  - `event_type.dart`: `enum EventType { wedding, holud, birthday, corporate, preWedding, other; bool get requiresBrideGroom }`
  - `shift.dart`: `enum Shift { day, night, both }`
  - `assignment_role.dart`: `enum AssignmentRole { photographer, cinematographer, editor, assistant, drone }`
  - `payment_kind.dart`: `enum PaymentKind { advance, due, extra }`
  - `re_edit_status.dart`: `enum ReEditStatus { pending, inProgress, done, rejected }`
  - `booking_filter.dart`: `class BookingFilter { from, to, statuses, types, clientId, search, sort; isEmpty }`
  - `booking_sort.dart`: `enum BookingSort { dateDesc, dateAsc, createdAtDesc, clientNameAsc }`
  - All enums expose `fromString` / `name`
  - _Requirements: 1.3, 1.6, 2.1, 2.2, 7.4, 13.1_

- [x] 3.2 Create domain entities with `toJson` / `fromJson` / `copyWith` under `features/bookings/domain/`
  - `booking.dart`, `client.dart`, `assignment.dart`, `payment.dart`, `package.dart`, `status_history_entry.dart`, `re_edit_request.dart`, `task_progress.dart`
  - Field shape exactly per design "Data Models" section
  - Implement value-equality (override `==` and `hashCode` via `copyWith` or a generated `Equatable` mixin) so Property 9 round-trip can compare instances by structural equality
  - `ReEditRequest.isOverdue` getter computes `(status in {pending, inProgress}) AND deadline.isBefore(now)`
  - _Requirements: 2.1, 5.2, 7.2–7.4, 8.1–8.3, 9.1, 13.2_

- [x] 3.3 Create `features/public_booking/domain/` models
  - `public_booking_token.dart` — `class PublicBookingToken { token, studioName, studioLogoUrl?, supportedEventTypes, locale, expiresAt }`
  - `public_booking_request.dart` — `class PublicBookingRequest { id, studioId, title, eventType, date, startTime, endTime, shift, venue?, brideName?, groomName?, clientName, clientPhone, clientEmail?, notes?, status, submittedAt, updatedAt }`
  - `public_booking_request_status.dart` — `enum PublicBookingRequestStatus { pending, approved, rejected }`
  - All entities have `toJson` / `fromJson` / value equality
  - _Requirements: 6.5, 6.6, 6.8, 6.9, 13.14, 13.15_

- [x] 3.4 Property test: Round-trip serialization (Property 9)
  - **Property 9: Round-trip serialization** — for every domain entity in `{Booking, Client, Assignment, Payment, Package, StatusHistoryEntry, ReEditRequest, TaskProgress, PublicBookingRequest}` and any valid instance `e`, `E.fromJson(e.toJson()) == e` (structural equality)
  - **Validates: Requirements 13.2, 13.3, 13.4, 13.7, 13.9, 13.10, 13.11, 13.12, 13.13, 13.14**
  - One `glados` generator per domain entity in `test/bookings/generators/`; use `Generator.combine` for nested entities
  - Edge cases the generator must cover: null nullable fields, empty collections, max-length strings (title=120, name=80), special-character titles, Bengali characters in name fields, deeply-nested clientRequirements JSON
  - _Requirements: 13.2, 13.3, 13.4, 13.7, 13.9, 13.10, 13.11, 13.12, 13.13, 13.14_

---

### 4. Capability matrix extension

- [x] 4.1 Extend `core/role/capability.dart` with the 18 booking-specific Capability values
  - Append exactly: `viewAllBookings`, `viewAssignedBookings`, `viewOwnBookings`, `createBooking`, `editBooking`, `deleteBooking`, `advanceBookingStatus`, `cancelBooking`, `viewBookingPayments`, `viewBookingPayouts`, `editBookingPayments`, `editAssignment`, `toggleHidePayment`, `generatePublicBookingToken`, `approvePublicBooking`, `requestReEdit`, `assignReEdit`, `updateTaskProgress`
  - _Requirements: 11.1_

- [x] 4.2 Extend `core/role/role_policy.dart` `_matrix` with the booking bindings
  - Add the 18 entries exactly per design "Capability Extensions" section
  - Owner: every booking capability; Both: every booking capability; Manager: assigned-only set; Freelancer: own-only set
  - _Requirements: 11.1, 11.2_

- [x] 4.3 Add `RolePolicyDeniedException` typed exception in `core/role/role_policy_denied_exception.dart`
  - `class RolePolicyDeniedException implements Exception { final Capability capability; final UserRole role; final String message; }`
  - _Requirements: 11.6_

- [x] 4.4 Property test: Capability gating round-trip (Property 11 — booking-specific)
  - **Property 11: Capability gating round-trip** — for every `(role, capability)` pair where `capability` is one of the 18 booking-specific capabilities, `RolePolicy(role).can(capability)` returns true if and only if the static `_matrix[capability]` set contains `role`
  - **Validates: Requirements 11.1, 11.2, 11.6**
  - Use `glados` with `Generator.product(roleGen, bookingCapabilityGen)`; iterate exhaustively (96 combinations) plus 100 random iterations as a sanity check
  - _Requirements: 11.1, 11.2_

---

### 5. API classes

- [x] 5.1 Implement `features/bookings/data/booking_api.dart`
  - Constructor: `BookingApi(ApiClient client)`
  - Methods: `list(filter, page, pageSize)`, `get(remoteId)` returning the full `BookingDetailEnvelope { event, client, assignments, payments, package, statusHistory, reEditRequests, taskProgress }`, `create(Booking)`, `patch(remoteId, partial)`, `delete(remoteId)`, `transitionStatus(remoteId, from, to, note?)` exactly per design "Remote API Contract" section
  - On HTTP 409 from `transitionStatus`, throw a typed `StatusConflictException(serverStatus)` parsed from the response body
  - _Requirements: 13.1–13.6_

- [x] 5.2 Implement `features/bookings/data/client_api.dart`
  - Methods: `list(query)`, `get(remoteId)`, `searchByPhone(prefix)`, `create(Client)`, `patch(remoteId, partial)`
  - _Requirements: 13.7, 13.8_

- [x] 5.3 Implement `features/bookings/data/assignment_api.dart`
  - Methods: `create(bookingRemoteId, Assignment)`, `patch(bookingRemoteId, assignmentRemoteId, partial)`, `delete(bookingRemoteId, assignmentRemoteId)`
  - _Requirements: 13.9_

- [x] 5.4 Implement `features/bookings/data/payment_api.dart`
  - Methods: `create(bookingRemoteId, Payment)`, `patch(bookingRemoteId, paymentRemoteId, partial)`, `delete(bookingRemoteId, paymentRemoteId)`
  - _Requirements: 13.10_

- [x] 5.5 Implement `features/bookings/data/package_api.dart`
  - Methods: `list()`, `create(Package)`, `patch(remoteId, partial)`, `delete(remoteId)`
  - _Requirements: 13.11_

- [x] 5.6 Implement `features/bookings/data/status_api.dart`
  - Wraps the status-transition endpoint that lives on `BookingApi.transitionStatus`; this class handles the "append-only fetch" path: `getHistory(bookingRemoteId)` returning `List<StatusHistoryEntry>` from `GET /api/bookings/:id` (envelope subset)
  - _Requirements: 13.6_

- [x] 5.7 Implement `features/bookings/data/re_edit_api.dart`
  - Methods: `listByBooking(bookingRemoteId)`, `create(bookingRemoteId, ReEditRequest)`, `updateStatus(reEditRemoteId, toStatus)`
  - _Requirements: 13.12_

- [x] 5.8 Implement `features/bookings/data/task_progress_api.dart`
  - Methods: `listByBooking(bookingRemoteId)`, `upsert(bookingRemoteId, percentage, note)` — server uses the bearer-token user as the upsert key
  - _Requirements: 13.13_

- [x] 5.9 Implement `features/public_booking/data/public_booking_api.dart`
  - Owner-side methods (use `ApiClient` with bearer): `issueToken({expiresInDays?, maxUses?})`, `listPending()`, `approve(requestId)`, `reject(requestId, reason?)`
  - Visitor-side methods (use `ApiClient` with NO bearer; pass `?token=` in query): `peek(token)`, `submit(token, payload)`
  - For the visitor-side calls, the existing `ApiClient` does not inject a Bearer header when `SecureStore.readToken()` returns null — confirm this Foundation MVP behavior in the test
  - _Requirements: 13.14, 13.15_

- [x] 5.10 Unit tests for each `*Api` class with `MockClient`
  - Verify URL paths, query params, request bodies, JSON parsing, 401 → `ApiException(401)`, 409 → typed `StatusConflictException`, 5xx → `ApiException(5xx)`
  - _Requirements: 13.1–13.17_

---

### 6. Repository implementations + provider wiring

- [x] 6.1 Define repository interfaces under `features/bookings/domain/`
  - `booking_repository.dart`, `client_repository.dart`, `assignment_repository.dart`, `payment_repository.dart`, `package_repository.dart`, `status_repository.dart`, `re_edit_repository.dart`, `task_progress_repository.dart` exactly per design "Repository Contracts" section
  - `features/public_booking/domain/public_booking_repository.dart` exactly per design contract
  - _Requirements: 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0, 10.0_

- [x] 6.2 Implement `BookingRepositoryImpl` in `features/bookings/data/booking_repository_impl.dart`
  - Wires `BookingApi`, `BookingsDao`, `ClientsDao`, `AssignmentsDao`, `PaymentsDao`, `PackagesDao`, `StatusHistoryDao`, `ReEditRequestsDao`, `TaskProgressDao`, `OutboxDao`
  - `watchList(filter, policy, currentUserId, page)` — applies role-scope predicate at the Drift query level (Owner/Both: `studioId = currentUserId.studioId`; Manager: `studioId = currentUser.ownerId AND (createdBy = currentUserId OR EXISTS assignment)`; Freelancer: `createdBy = currentUserId OR EXISTS assignment`)
  - `watch(localId)`, `watchMonth(year, month, policy, currentUserId)` — same scoping logic
  - `save(booking, policy)` — verifies `policy.can(createBooking)` for new (no remoteId) or `policy.can(editBooking)` for update; commits to Drift FIRST with `pending=true`, `updatedAt=now`; enqueues `OutboxItem(entityType: 'booking', op: ...)`; on success the worker drains it
  - `delete(localId, policy)` — verifies `policy.can(deleteBooking)`; soft-delete via Drift flag, then enqueue
  - `refreshFromRemote({filter?, singleEventId?})` — GET `/api/bookings` or `/api/bookings/:id`; upsert Booking + cascading Client + Assignments + Payments + StatusHistory (via `status_history_dao.upsertIfNotExists` to preserve append-only) + ReEditRequests + TaskProgress
  - On any 401, the existing Foundation MVP `forceLogoutStream` triggers; this repo does not handle 401 directly
  - _Requirements: 1.1, 1.4, 1.5, 1.7, 2.3, 5.1, 10.1, 10.2, 10.6, 11.6, 13.1, 13.2, 13.3, 13.4, 13.5_

- [x] 6.3 Implement `ClientRepositoryImpl` in `features/bookings/data/client_repository_impl.dart`
  - Local-first searchByPhone (Drift LIKE prefix), then background remote refresh
  - `save(client)` — Drift upsert + outbox
  - _Requirements: 2.7, 13.7, 13.8_

- [x] 6.4 Implement `AssignmentRepositoryImpl`, `PaymentRepositoryImpl`, `PackageRepositoryImpl` in `features/bookings/data/`
  - Each follows the same local-first + outbox pattern
  - `PaymentRepository.aggregateForBooking` returns the result of `payments_dao.aggregateForBooking`
  - All three verify the corresponding Capability before any side effect (Property 11 enforcement)
  - _Requirements: 2.9, 11.6, 13.9, 13.10, 13.11_

- [x] 6.5 Implement `StatusRepositoryImpl` in `features/bookings/data/status_repository_impl.dart`
  - `transition({bookingId, expectedFrom, to, changedByUserId, policy, note?})`:
    1. Throw `StatusTransitionDeniedException` if `BookingStatusMachine.canTransition(policy.role, expectedFrom, to) == false`
    2. Drift INSERT a new `StatusHistoryEntry(pending=true, fromStatus, toStatus, changedByUserId, at=now, note)` AND UPDATE `Booking.status = to, updatedAt = now`
    3. Enqueue an `OutboxItem(entityType: 'statusHistory', op: 'create', payload)`
    4. On worker drain success: mark statusHistory as synced
    5. On worker drain 409 (server status mismatch): drop the local pending statusHistory row via `status_history_dao.deletePendingForBooking(...)`, refresh booking from remote, surface a non-blocking event via a `statusConflictStream` that the UI listens on
  - _Requirements: 3.1–3.11, 10.7, 10.8_

- [x] 6.6 Implement `ReEditRepositoryImpl` in `features/bookings/data/re_edit_repository_impl.dart`
  - `nextRoundFor(bookingId)` delegates to DAO
  - `request(...)` verifies `policy.can(requestReEdit)`, persists locally, enqueues outbox
  - `updateStatus(...)` verifies `policy.can(assignReEdit)` (or self-update for the assigned editor), persists locally, enqueues outbox
  - _Requirements: 7.1–7.7, 11.6_

- [x] 6.7 Implement `TaskProgressRepositoryImpl` in `features/bookings/data/task_progress_repository_impl.dart`
  - `upsert(...)` verifies `policy.can(updateTaskProgress)`; for non-Owner/Both/Manager roles, additionally verifies `userId == currentUserId AND assignmentExists`
  - Drift composite-key upsert; enqueue outbox
  - _Requirements: 8.1–8.5, 11.6_

- [x] 6.8 Implement `PublicBookingRepositoryImpl` in `features/public_booking/data/public_booking_repository_impl.dart`
  - Owner-side methods verify the corresponding Capability (`generatePublicBookingToken`, `approvePublicBooking`)
  - Visitor-side `peek` and `submit` do NOT call any role check; they rely on the server's HMAC token verification
  - Approve creates a local `Booking` row by calling `BookingRepository.save` on the materialized event from the server response
  - _Requirements: 6.1–6.11, 11.6_

- [-] 6.9 Wire repository providers in `core/providers.dart`
  - Add the 9 booking API providers and the 9 booking repository providers exactly per design "Provider Tree Extensions" section
  - Add `BookingFilter`, `BookingSearch`, `BookingSort`, `bookingListPage`, `calendarVisibleMonth` `StateProvider`s
  - Add the booking-related `StreamProvider`/`FutureProvider.family` providers
  - _Requirements: 1.0–10.0_

- [~] 6.10 Property test: Role-scoped booking visibility (Property 2)
  - **Property 2: Role-scoped booking visibility** — for any fixture `(users, bookings, assignments)` AND any `currentUser`, `BookingRepository.watchList(filter, policy, currentUserId)` returns exactly the role-scope subset
  - **Validates: Requirements 1.1, 11.5**
  - Use a `glados` generator that builds a small studio (1–3 users per role × up to 20 bookings × up to 50 assignments); for each user, compare `repo.watchList` output against an in-test reference predicate
  - _Requirements: 1.1, 11.5_

- [~] 6.11 Property test: Booking offline-write durability (Property 5)
  - **Property 5: Booking offline-write durability** — for any entity type `T` in `{booking, client, assignment, payment, package, reEditRequest, taskProgress}` and any valid mutation, when the API mock throws `SocketException`, the local Drift row exists with `pending=true` AND exactly one `OutboxItem` exists with the matching entity type/id/op
  - **Validates: Requirements 10.1, 10.2**
  - Generate random valid instances per entity; parameterize the test by entity type
  - _Requirements: 10.1, 10.2_

- [~] 6.12 Property test: Status-conflict 409 reconciliation (Property 6)
  - **Property 6: Status-conflict 409 reconciliation** — for any triple `(localFrom, localTo, serverCurrent)` where `serverCurrent != localFrom`, simulate a 409 on `transitionStatus` and assert: local pending statusHistory row is dropped, `Booking.status == serverCurrent`, conflict signal emitted
  - **Validates: Requirements 3.11, 10.8**
  - _Requirements: 3.11, 10.8_

- [~] 6.13 Property test: Append-only entity tier (Property 7)
  - **Property 7: Append-only entity tier (Tier C)** — for any sequence of remote drains involving `statusHistory` or `reEditStatus` rows, no existing local row is ever modified or deleted; new rows are appended; identical rows dedupe by `remoteId`
  - **Validates: Requirements 10.7, 15.4, 15.9**
  - _Requirements: 10.7, 15.4_

- [~] 6.14 Property test: Last-write-wins by updatedAt (Property 8)
  - **Property 8: Last-write-wins by updatedAt** — for any pair `(local, remote)` of Tier A rows, the reconciliation result is the row with the strictly newer `updatedAt`; on tie, local wins; on local newer, remote is replaced
  - **Validates: Requirements 10.6, 15.5, 15.6, 15.7**
  - _Requirements: 10.6, 15.5_

- [~] 6.15 Property test: Hide_Payment_Flag enforcement (Property 3)
  - **Property 3: Hide_Payment_Flag enforcement** — for every `(role, hidePaymentFromTeam)` pair, `shouldShowPayment(role, hidePaymentFromTeam)` returns true iff `policy.can(viewBookingPayments) AND NOT (role == manager AND hidePaymentFromTeam)`
  - **Validates: Requirements 5.3, 5.4, 11.3**
  - Pure-function test; iterates exhaustively (8 combinations) plus 100 random
  - _Requirements: 5.3, 5.4, 11.3_

- [~] 6.16 Property test: Assignments scope per role (Property 4)
  - **Property 4: Assignments scope per role** — for any Booking with arbitrary Assignments and any currentUser, the assignments-list filter returns all for Owner/Both/Manager and only `userId == currentUser.id` for Freelancer
  - **Validates: Requirement 11.4**
  - _Requirements: 11.4_

---

### 7. Outbox worker extensions

- [~] 7.1 Extend `core/sync/outbox_worker.dart` `_drain` switch with the new entity types
  - Add cases: `booking`, `client`, `assignment`, `payment`, `package`, `statusHistory`, `reEditRequest`, `reEditStatus`, `taskProgress`, `publicBookingApprove`, `publicBookingReject`
  - Each case calls a private `_drain<EntityName>(item)` method
  - _Requirements: 10.1–10.8_

- [~] 7.2 Implement `_drainBooking`, `_drainClient`, `_drainAssignment`, `_drainPayment`, `_drainPackage`, `_drainReEditRequest`, `_drainTaskProgress` (Tier A)
  - Each: read pending row from DAO; call API method (POST for create, PATCH for update, DELETE for delete); on 2xx update local row to `pending=false`, set `remoteId`, set `updatedAt = server.updatedAt`; on 5xx/network bump attempts; on 4xx mark manual-retry
  - Apply Property 8 reconciliation when 2xx response indicates the server's `updatedAt` is newer than local: discard local mutation
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6_

- [~] 7.3 Implement `_drainStatusHistory` (Tier C with 409 special case)
  - Read pending statusHistory row; POST to `/api/bookings/:bookingRemoteId/status` with `{fromStatus, toStatus, note}`
  - On 2xx: mark synced, set `remoteId`
  - On 409: drop the local pending statusHistory row (`status_history_dao.deletePendingForBooking`); call `BookingRepository.refreshFromRemote(singleEventId: ...)`; emit a non-blocking event via `statusConflictStream`
  - _Requirements: 3.11, 10.7, 10.8_

- [~] 7.4 Implement `_drainReEditStatus` (Tier C — append-only status changes)
  - Read pending reEditStatus row; PATCH to `/api/reedits/:reEditId/status`
  - On 2xx: mark synced; never overwrite an existing entry
  - _Requirements: 7.6, 10.7_

- [~] 7.5 Implement `_drainPublicApprove` and `_drainPublicReject`
  - Approve: POST `/api/bookings/pending-public/:requestId/approve`; on 2xx upsert resulting Booking via `BookingRepository.save` AND remove the pending row from `PublicBookingRequestsDao`
  - Reject: POST `/api/bookings/pending-public/:requestId/reject`; on 2xx remove the pending row
  - _Requirements: 6.8, 6.9, 13.15_

- [~] 7.6 Add JSON serializers for each booking-entity payload in `features/bookings/data/booking_serializers.dart`
  - One serializer per entity that converts a Drift row → API payload AND a Drift row → `OutboxItem.payloadJson`
  - Reuses the domain `toJson`/`fromJson` from Wave 3 to avoid duplication
  - _Requirements: 13.1–13.17_

- [~] 7.7 Unit test outbox drain for each new entity type
  - Mock `*Api` per entity; assert: 2xx clears pending; 5xx bumps attempts; 4xx (non-409) marks manual-retry; 409 (statusHistory only) triggers drop+refresh+conflict stream
  - _Requirements: 10.1–10.8_

---

### 8. Application layer (Riverpod controllers)

- [~] 8.1 Implement `BookingListController` in `features/bookings/application/booking_list_controller.dart`
  - `AsyncNotifierProvider<BookingListController, List<Booking>>` family-keyed by `BookingFilter`
  - `build(filter)` reads `bookingListProvider(filter)`, applies search debounce (300ms via `Timer`), exposes `nextPage()`, `refresh()`
  - _Requirements: 1.4, 1.5, 1.7, 1.8, 1.12_

- [~] 8.2 Implement `BookingEditController` in `features/bookings/application/booking_edit_controller.dart`
  - `AsyncNotifierProvider<BookingEditController, BookingDraft>` family-keyed by `String? eventId` (null for new)
  - `build(eventId?)` loads existing or creates fresh draft; exposes `save()`, `cancel()`, field setters
  - On `save`, validates: title length 1–120, date present, endTime ≥ startTime, client selected, eventType selected, drive link matches Google Drive/Docs URL pattern (Property-tested), bride/groom required iff event type is wedding/holud
  - On valid submit: calls `BookingRepository.save(booking, policy)`, on success returns to detail
  - On concurrent remote update detected via `bookingProvider(id)` emit while editing: emit a non-blocking SnackBar event "newer remote data available — Reload" with an action callback that re-loads the draft
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.7, 2.11, 2.12, 2.13, 11.6_

- [~] 8.3 Implement `BookingDetailController` in `features/bookings/application/booking_detail_controller.dart`
  - `AsyncNotifierProvider<BookingDetailController, BookingDetailViewModel>` family-keyed by event id
  - `build(id)` returns a composite view model: `(booking, client, assignments, payments, package, statusHistory, reEditRequests, taskProgress)`
  - Exposes `transitionStatus(toStatus, note?)`, `cancel(reason)`, `editPayment(...)`, `editAssignment(...)` — each wired through the corresponding repository
  - _Requirements: 5.1, 5.2, 5.7, 5.8_

- [~] 8.4 Implement `CalendarController` in `features/bookings/application/calendar_controller.dart`
  - Watches `calendarVisibleMonthProvider`; on month change, invalidates and re-queries `calendarMonthProvider(yyyymm)`
  - Exposes `nextMonth()`, `prevMonth()`, `selectDay(day)`
  - _Requirements: 4.1, 4.2, 4.3, 4.6_

- [~] 8.5 Implement `ClientSearchController` in `features/bookings/application/client_search_controller.dart`
  - Wraps `clientSearchProvider` with debounce; surfaces `getOrCreate(name, phone, ...)` for inline-creation flow
  - _Requirements: 2.7, 13.7, 13.8_

- [~] 8.6 Implement `PackagePickerController`, `ReEditController`, `TaskProgressController` in `features/bookings/application/`
  - Thin wrappers around their repositories; expose UI-friendly `submit*` methods
  - _Requirements: 2.8, 7.1–7.6, 8.1–8.4_

- [~] 8.7 Implement `PublicBookingFormController` in `features/public_booking/application/public_booking_form_controller.dart`
  - `AsyncNotifierProvider<PublicBookingFormController, PublicBookingFormState>` family-keyed by token string
  - `build(token)` calls `PublicBookingRepository.peek(token)`; on success exposes `submit(payload)` that calls `submit(token, payload)` and surfaces success or inline error
  - _Requirements: 6.3, 6.4, 6.5, 6.6_

- [~] 8.8 Property test: Public Booking Token validity gate (Property 10)
  - **Property 10: Public Booking Token validity gate** — for any token state in `{valid, expired, exhausted-uses, malformed, server-revoked}`, `peek(token)` succeeds only on `valid` and renders the form only on success; `submit(token, payload)` succeeds only when the token state at submission time is `valid`
  - **Validates: Requirements 6.3, 6.4**
  - Use a fake `PublicBookingApi` whose response varies by token state generator; verify state machine
  - _Requirements: 6.3, 6.4_

---

### 9. Checkpoint — non-UI tests pass

- [~] 9. Run `flutter pub get && flutter analyze && flutter test`
  - Ensure all unit + property tests written so far (Waves 1–8) pass
  - If any property test fails (e.g. seed surfaces a counterexample), capture the failing example, classify it as a real bug or generator over-fit, and either fix the implementation or tighten the generator before proceeding
  - _Ensure all tests pass, ask the user if questions arise._

---

### 10. ARB file additions

- [~] 10.1 Extend `lib/l10n/app_en.arb` with the `bookings_*` and `public_booking_*` and `re_edit_*` keys
  - Use the sample namespace from design "ARB Extensions (sample keys)" as a starting list; add every label, button, validation message, and status display name surfaced by booking screens
  - For each key, add a metadata block `@<key>: { description }`
  - _Requirements: 12.1, 12.2_

- [~] 10.2 Extend `lib/l10n/app_bn.arb` with the same keys, every value containing a non-empty Bengali translation
  - Use the corresponding Bengali sample as a starting point; cover every key added in 10.1
  - _Requirements: 12.1, 12.2, 12.7_

- [~] 10.3 Run `flutter gen-l10n` and commit the regenerated `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_bn.dart`
  - _Requirements: 12.1_

- [~] 10.4 Property test: ARB key parity for booking namespace
  - For every key added in 10.1, assert it exists with a non-empty value in BOTH `app_en.arb` and `app_bn.arb` (parses both ARB files and compares key sets)
  - Folds into / extends Foundation MVP Property 11 (AppStrings shim parity)
  - _Requirements: 12.1, 12.2_

---

### 11. Shared booking widgets

- [~] 11.1 Implement `features/bookings/presentation/widgets/booking_status_badge.dart`
  - Stateless widget rendering background+foreground color per status (per design status-color contract); reuses existing `AppColors` tokens
  - Inter typography from existing `AppTheme`; soft 1-px border; no glow
  - _Requirements: 1.13_

- [~] 11.2 Implement `features/bookings/presentation/widgets/booking_list_row.dart`
  - Renders title, client name, date+time, status badge, payment subtitle (gated by `Property 3` `shouldShowPayment` predicate)
  - Bengali numerals for date+amount when `locale=bn AND bnNumerals=true` via `BookingFormat` helpers
  - _Requirements: 1.10, 1.11, 1.13, 5.3, 5.4, 11.3_

- [~] 11.3 Implement `features/bookings/presentation/widgets/booking_filter_bar.dart`
  - Date-range picker, status multi-select chip row, type multi-select chip row, client autocomplete field
  - Reads `bookingFilterProvider`; writes through on every change
  - _Requirements: 1.3, 1.4_

- [~] 11.4 Implement `features/bookings/presentation/widgets/status_timeline.dart`
  - Vertical timeline of `StatusHistoryEntry` rows
  - Each row: `from → to`, actor name, formatted timestamp (relative if <24h via `BookingFormat.relative`, absolute otherwise), optional truncated note with "more" expand
  - Pending indicator (small orange dot) when row's `pending == true`
  - Cancellation row red, reason expanded by default
  - _Requirements: 3.9, 3.10, 9.1–9.6_

- [~] 11.5 Implement `features/bookings/presentation/widgets/client_picker_field.dart`
  - Text field with autocomplete via `clientSearchProvider`; "+ New client" affordance opens `NewClientDialog`
  - _Requirements: 2.7, 13.8_

- [~] 11.6 Implement `features/bookings/presentation/widgets/package_picker_field.dart`
  - Dropdown of packages from `packageListProvider`; "Custom price" option swaps to a numeric input
  - On package select, emits the package's `coverageHours` and `extraHourRate` to the parent form so it can pre-fill those fields
  - _Requirements: 2.8_

- [~] 11.7 Implement `features/bookings/presentation/widgets/assignments_editor.dart`
  - List of editable `Assignment` rows; each row has staff picker, AssignmentRole selector, payout amount input
  - Add-row affordance; per-row remove
  - For Freelancer role, hide other-staff rows and lock the staff field to self
  - _Requirements: 2.9, 11.4_

- [~] 11.8 Implement `features/bookings/presentation/widgets/payment_summary_card.dart`
  - Renders advance / due / extra / total computed via `PaymentRepository.aggregateForBooking`
  - Visibility gated by `Property 3` predicate
  - Bengali numerals via `BookingFormat.money`
  - _Requirements: 5.2, 5.3, 5.4, 11.3, 12.4_

- [~] 11.9 Implement `features/bookings/presentation/widgets/re_edit_card.dart`
  - Renders one ReEditRequest: round, status badge, editor, deadline, expand-to-show notes + reference images
  - Overdue indicator (red border + label) when `request.isOverdue == true`
  - _Requirements: 7.7, 7.8_

- [~] 11.10 Implement `features/bookings/presentation/widgets/task_progress_section.dart`
  - "My progress" sub-section (current user's row + edit affordance) and "All progress" sub-section (visible only to Owner/Both/Manager per Property 11)
  - Slider 0–100 step 5 + notes input (length 0–500) in edit mode
  - Bengali numerals on percentage via `BookingFormat.percent`
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 11.4_

- [~] 11.11 Implement `features/bookings/presentation/widgets/calendar_month_grid.dart`
  - 7×6 monthly grid; each day cell renders day-of-month (Bengali numerals when applicable) + up to 3 status-colored dots; `+N` overflow when more than 3
  - On tap day, emits selection up to controller
  - _Requirements: 4.1, 4.2, 4.3, 4.8_

- [~] 11.12 Implement `features/bookings/presentation/widgets/day_events_sheet.dart`
  - Bottom sheet listing `Booking` rows for the selected day, ordered by start time
  - On tap row, navigates to `BookingDetailScreen` via central app router
  - _Requirements: 4.4, 4.5_

---

### 12. Booking screens

- [~] 12.1 Implement `features/bookings/presentation/booking_list_screen.dart`
  - Watches `bookingListProvider(filter)`; renders `LensLoader` / `EmptyState` / `ErrorState` / content via `AsyncValue.when`
  - App bar: title, search field (debounced 300ms), filter button (opens `BookingFilterBar` as a bottom sheet), sort selector, calendar icon (navigates to `CalendarScreen`)
  - List body: `ListView.builder` of `BookingListRow`; lazy pagination triggered when scroll within 200px of bottom
  - FAB: navigates to `BookingEditScreen` (new mode)
  - "Pending requests" filter pill (Owner/Both only — gated by `Property 11`) shows `PendingPublicBookingsSection`
  - "Share booking link" overflow action (Owner/Both only) opens `SharePublicLinkDialog`
  - OfflineBanner via Foundation MVP `OfflineBanner` widget
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7, 1.8, 1.9, 1.10, 1.12, 1.14, 6.1, 6.7_

- [~] 12.2 Implement `features/bookings/presentation/booking_edit_screen.dart`
  - `ConsumerStatefulWidget`; uses `Form` with `GlobalKey<FormState>`
  - Sections in order: Title, EventType selector, Date+StartTime+EndTime+Shift, Venue+Outdoor, Bride/Groom (only when EventType requires), Client picker, Package picker (with custom price branch), Coverage hours + Extra hour rate, Drive link, Notes, Chief photographer + chief hours, Assignments editor, Hide-payment toggle (Owner/Both only)
  - On Save: calls `BookingEditController.save()`, navigates to `BookingDetailScreen` on success, shows inline errors on failure
  - On Cancel: confirm dialog if dirty, then pop
  - Bilingual labels via `AppLocalizations`; Bengali numerals on numeric inputs via `BookingFormat`
  - SnackBar listener for "newer remote data" event from controller
  - _Requirements: 2.1–2.4, 2.5, 2.7, 2.8, 2.10, 2.11, 2.12, 2.13, 2.14, 11.6, 12.4, 12.6_

- [~] 12.3 Implement `features/bookings/presentation/booking_detail_screen.dart`
  - Watches `bookingDetailControllerProvider(id)`; on mount triggers `BookingRepository.refreshFromRemote(singleEventId: id)` in background
  - Sections: Header (title, status badge, type, date/time/shift), Client info, Schedule, Package, Payment summary (gated), Assignments list (filtered for Freelancer), Status timeline, Re-edit requests, Task progress section, Attachments + Notes, Client requirements
  - App bar Edit button (Owner/Both/Manager via Property 11); next-status / Cancel actions per status + role
  - "Request Re-edit" CTA visible only when status ∈ `{shotComplete, delivered, completed}` AND user can `requestReEdit`
  - Drive link rendered as tappable `url_launcher.launchUrl`
  - Bengali numerals everywhere via `BookingFormat`
  - _Requirements: 5.1–5.11, 7.1, 8.1, 8.4, 11.3, 11.4_

- [~] 12.4 Implement `features/bookings/presentation/calendar_screen.dart`
  - Header: month name + year (Bengali numerals when applicable), prev/next chevrons
  - Body: `CalendarMonthGrid` watching `calendarMonthProvider(visibleMonth)`
  - Tap day opens `DayEventsSheet`
  - Add control opens `BookingEditScreen` with selected day pre-filled
  - Animated month transition 280ms
  - OfflineBanner
  - _Requirements: 4.1–4.10_

- [~] 12.5 Implement `features/bookings/presentation/re_edit_request_screen.dart`
  - Lists every ReEditRequest across all bookings the user is permitted to see (queries via a new `reEditAllProvider` that aggregates per-booking watches)
  - Filters: status (multi-select), assigned-to-me (Editor view)
  - Tap row navigates back to the corresponding `BookingDetailScreen` re-edit section
  - Owner/Manager view shows all; Editor view shows only own assignments
  - _Requirements: 7.1–7.10_

- [~] 12.6 Implement booking dialogs in `features/bookings/presentation/dialogs/`
  - `new_client_dialog.dart` — inline Client creation form with name + phone + email + address + DOB + anniversary
  - `cancel_booking_dialog.dart` — cancel reason input (1–500 chars), confirm cancels via `BookingDetailController`
  - `share_public_link_dialog.dart` — calls `PublicBookingRepository.issueToken`, shows generated URL with copy + share affordances
  - `re_edit_request_form.dart` — round (auto-incremented), editor picker, deadline date (≥ today), reference image attachments (URL list, 0–10), notes (length 0–2000)
  - _Requirements: 2.7, 3.8, 6.1, 6.2, 7.2, 7.3_

- [~] 12.7 Widget tests for each booking screen (golden + interaction)
  - `BookingListScreen`: role-scoped rendering for Owner / Manager / Freelancer fixtures; status badge color per status; offline banner toggles
  - `BookingEditScreen`: bride/groom field appears only for `wedding`/`holud`; validators block submit; Hide_Payment_Flag toggle visibility
  - `BookingDetailScreen`: payment summary visibility per `(role, hidePaymentFromTeam)` combinations
  - `CalendarScreen`: golden for fixed month with known booking distribution
  - `ReEditRequestScreen`: overdue indicator on past-deadline requests
  - _Requirements: 1.1, 1.13, 2.2, 2.10, 4.1, 5.3, 5.4, 7.8, 11.3_

---

### 13. Public booking screens

- [~] 13.1 Implement `features/public_booking/presentation/public_booking_form_screen.dart`
  - `ConsumerStatefulWidget` wired to `publicBookingFormControllerProvider(token)`
  - On `peek` success: render the form bound to the issuing studio's name + logo + locale; field set per Requirement 6.5
  - On `peek` failure: render the invalid-link screen with a request-new-link instruction
  - On submit: validates fields locally; on submit success route to `PublicBookingSuccessScreen`; on offline, render inline error
  - **Critical:** uses `Localizations.override` to honor the studio-provided `locale` (en or bn) regardless of device locale
  - _Requirements: 6.3, 6.4, 6.5, 6.6, 6.10, 6.11_

- [~] 13.2 Implement `features/public_booking/presentation/public_booking_success_screen.dart`
  - Static thank-you page; no provider dependencies on the authenticated tree
  - _Requirements: 6.6_

- [~] 13.3 Implement `features/public_booking/presentation/pending_public_bookings_section.dart`
  - Embedded section in `BookingListScreen` (Owner/Both only)
  - Watches `pendingPublicBookingsProvider`; lists each `PublicBookingRequest` with Approve / Reject actions
  - On Approve, calls `PublicBookingRepository.approve(id)`; on Reject, calls `reject(id)`
  - _Requirements: 6.7, 6.8, 6.9_

- [~] 13.4 Register the public-booking route in `core/navigation/app_router.dart` as a NON-AUTH-GUARDED route
  - Add `RouteNames.publicBooking` and `RouteNames.publicBookingSuccess` to the explicit non-auth-guarded route list (next to login, register, forgot, accept-invite)
  - Verify with a unit test that a non-authenticated session lands on `PublicBookingFormScreen` without redirect to Login
  - _Requirements: 6.3, 6.10_

- [~] 13.5 Widget test: Public booking flow happy path + error states
  - Mock `PublicBookingApi.peek` to return valid token → form renders; mock to throw 410 → error screen renders
  - Mock `submit` to return 201 → routes to success; mock to throw 400 → inline error
  - With `connectivityProvider == false`, submit shows inline offline error and never calls `submit`
  - _Requirements: 6.3, 6.4, 6.6, 6.11_

---

### 14. Wire into app shell + central router

- [~] 14.1 Extend `core/navigation/app_router.dart` with the booking routes
  - Add: `bookings → BookingListScreen`, `calendar → CalendarScreen`, `bookingNew → BookingEditScreen(eventId: null)`, `bookingEdit → BookingEditScreen(eventId: arg)`, `bookingDetail → BookingDetailScreen(eventId: arg)`, `reEditRequests → ReEditRequestScreen`, `pendingPublicBookings → BookingListScreen(filter: pending)`, `publicBooking → PublicBookingFormScreen(token: arg)`, `publicBookingSuccess → PublicBookingSuccessScreen`
  - Auth-guard every route EXCEPT `publicBooking` and `publicBookingSuccess`
  - _Requirements: 1.9, 1.14, 4.5, 4.7, 5.5, 6.3, 7.7, 11.7_

- [~] 14.2 Wire the central FAB on `DashboardScreen` to navigate to `RouteNames.bookingNew`
  - Replaces the Foundation MVP "New Booking" snackbar stub with a real route push
  - _Requirements: 1.14_

- [~] 14.3 Add a "Calendar" entry in the `DashboardScreen` drawer under the Operations section
  - Navigates to `RouteNames.calendar`
  - _Requirements: 4.0_

- [~] 14.4 Add a calendar-icon action in the `BookingListScreen` app bar
  - Navigates to `RouteNames.calendar`
  - _Requirements: 4.0_

---

### 15. Backend controller activation (Node.js + Prisma)

> All paths below are relative to `backend/`. Each controller currently exists as a stub that uses the existing Prisma singleton (already fixed in Foundation MVP). This wave fills in real implementations against the Prisma schema (which already has every table per the project description).

- [~] 15.1 Implement `backend/controllers/bookingController.js`
  - Handlers: `list`, `get`, `create`, `update`, `delete`, `transitionStatus`
  - `list` applies the role-scope filter from Requirement 1.1 server-side: Owner/Both → `studioId = req.user.studioId`; Manager → `studioId = req.user.ownerId AND (createdBy = req.user.id OR EXISTS Assignment(userId = req.user.id))`; Freelancer → `createdBy = req.user.id OR EXISTS Assignment(userId = req.user.id)`
  - `get` returns the full envelope `{ event, client, assignments, payments, package, statusHistory, reEditRequests, taskProgress }` via Prisma `include`
  - `transitionStatus` re-runs `BookingStatusMachine.canTransition` server-side AND verifies `req.body.fromStatus === db.event.status`; on mismatch responds 409 with `{ error: { code: "STATUS_CONFLICT", message, serverStatus } }`
  - All handlers respect 14.11 / 14.12 / 14.13 error contract
  - _Requirements: 13.1–13.6, 14.1, 14.11–14.13_

- [~] 15.2 Implement `backend/controllers/clientController.js`
  - Handlers: `list`, `get`, `create`, `update`, `searchByPhone(prefix)` returning Clients whose `phone` starts with the prefix AND `studioId = req.user.studioId`
  - _Requirements: 13.7, 13.8, 14.2_

- [~] 15.3 Implement `backend/controllers/assignmentController.js`
  - Handlers: `create`, `update`, `delete` scoped to a booking
  - Verify that the assignee belongs to the same studio (or is the Owner/Freelancer themselves) before persisting
  - _Requirements: 13.9, 14.3_

- [~] 15.4 Implement `backend/controllers/paymentController.js`
  - Handlers: `create`, `update`, `delete` scoped to a booking
  - Maintain `(advance + due + extra) == total` aggregate consistency at the row level (no aggregate column to maintain — totals computed on read)
  - _Requirements: 13.10, 14.4_

- [~] 15.5 Implement `backend/controllers/packageController.js`
  - Handlers: `list`, `create`, `update`, `delete` scoped to studio
  - _Requirements: 13.11, 14.5_

- [~] 15.6 Implement `backend/controllers/statusController.js`
  - Single handler: `transitionStatus` (callable from `bookingController` or directly mounted at `/api/bookings/:id/status`)
  - Re-runs `BookingStatusMachine.canTransition` server-side AND verifies `fromStatus` matches DB; on mismatch returns 409
  - On success: writes a `StatusHistory` row AND updates `Event.status` in a single Prisma transaction
  - _Requirements: 13.6, 14.6_

- [~] 15.7 Implement `backend/controllers/reeditController.js`
  - Handlers: `create`, `listByBooking`, `updateStatus`
  - Auto-increments `round` to `max(existing rounds for booking) + 1` when client does not supply it; on supplied round verifies uniqueness via the `(bookingId, round)` unique key
  - _Requirements: 13.12, 14.7_

- [~] 15.8 Implement `backend/controllers/taskController.js`
  - Handlers: `upsert` (keyed by `(bookingId, req.user.id)`) and `listByBooking`
  - Verifies that the actor has at least one `Assignment` on the Booking before allowing upsert
  - _Requirements: 13.13, 14.8_

- [~] 15.9 Implement `backend/controllers/clientBookingController.js`
  - Handlers: `issueToken` (Owner/Both, HMAC-signed token with `{studioId, exp, maxUses}`), `peekToken` (unauthenticated; verifies HMAC + expiry + uses), `submit` (unauthenticated; verifies token, increments uses, creates `PublicBookingRequest`), `listPending` (Owner/Both), `approve`, `reject`
  - `approve` materializes a real `Event` row + creates or links a `Client` by phone match within the studio
  - Token signing uses `process.env.PUBLIC_BOOKING_SIGNING_KEY` (HMAC-SHA256, base64url encoding)
  - _Requirements: 6.2, 6.6, 6.8, 6.9, 13.14, 13.15, 14.9_

- [~] 15.10 Add or update Express routes in `backend/routes/bookings.js`, `backend/routes/clients.js`, `backend/routes/packages.js`, `backend/routes/public.js`, `backend/routes/team.js`
  - Mount each handler under the path documented in design "Remote API Contract"
  - Apply the existing `requireAuth` middleware to authenticated endpoints; do NOT apply to `/api/public/booking` GET/POST
  - Apply role middleware where the design specifies (`Owner/Both` for token issuance and approve/reject)
  - _Requirements: 13.1–13.17, 14.10–14.13_

- [~] 15.11 Backend integration smoke tests (1–3 examples per endpoint)
  - Use `supertest` against the Express app with a seeded Postgres DB; verify happy-path 2xx responses + error 4xx responses
  - Verify the role-scope filter on `GET /api/bookings` returns the documented subset for Owner / Manager / Freelancer fixtures
  - Verify `POST /api/bookings/:id/status` returns 409 when `fromStatus` does not match server state
  - _Requirements: 13.1–13.17, 14.1, 14.6_

---

### 16. Cleanup & legacy removal

- [~] 16.1 Delete the placeholder `lib/screens/bookings_screen.dart` and `lib/screens/calendar_screen.dart`
  - Search for any `import` references to those files; remove or migrate to `RouteNames.bookings` / `RouteNames.calendar`
  - Run `flutter analyze`; expected: zero broken imports
  - _Requirements: 1.0, 4.0_

- [~] 16.2 Final pass: confirm no booking-related logic remains in `lib/screens/` outside of the `features/bookings/` and `features/public_booking/` folders
  - `grep -r "Booking" lib/screens/` should return zero hits
  - _Requirements: 1.0, 2.0, 4.0, 5.0_

---

### 17. Final verification

- [~] 17.1 Run `flutter analyze` → expected zero errors AND zero new warnings introduced by this slice
  - _Requirements: All_

- [~] 17.2 Run `flutter test` → expected all unit, widget, and property tests pass
  - 12 design Correctness Properties each have a corresponding optional test sub-task in Waves 2, 3, 4, 6, 8, 10
  - _Requirements: All testable properties_

- [~] 17.3 Run `flutter build apk --debug --dart-define=API_BASE_URL=...` smoke build
  - Verify build succeeds; APK installs and launches; navigate Dashboard → Booking List → New Booking → save → Detail → status transition; verify offline-first behavior by toggling airplane mode mid-flow
  - _Requirements: 1.1, 1.14, 2.3, 3.4, 5.1, 10.1_

- [~] 17.4 Run backend `npm test` (if test suite exists) AND a manual smoke against `npm run dev`
  - Verify all booking endpoints respond with documented shapes
  - _Requirements: 14.1–14.14_

- [~] 17.5 Final checkpoint — Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional test sub-tasks; they may be skipped for a faster MVP but are strongly recommended (especially the property tests for `BookingStatusMachine` (P1), role-scoped visibility (P2), offline-write durability (P5), and serializer round-trip (P9) — these guard against the hardest-to-debug regressions).
- All 12 design Correctness Properties have a corresponding test task: P1 → 2.4; P2 → 6.10; P3 → 6.15; P4 → 6.16; P5 → 6.11; P6 → 6.12; P7 → 6.13; P8 → 6.14; P9 → 3.4; P10 → 8.8; P11 → 4.4; P12 → 2.5 + 10.4.
- Property tests use `glados` (added in Wave 0). Each test is tagged `Feature: bookings-module, Property N: <text>` per Foundation MVP convention.
- Every requirements clause from Requirements 1 through 15 is cited at least once across the task list — verified by the cross-reference at the bottom of `requirements.md`.
- Backend tasks (Wave 15) assume the Prisma schema already contains every required table (per the project description). If any table turns out to be missing, add a Prisma migration in Wave 15.0 before the controller implementations.
- The Outbox worker extension (Wave 7) re-uses the Foundation MVP backoff schedule (2s → 4s → ... → 300s, capped at 5 manual-retry attempts) and the existing top-bar sync indicator. This slice does NOT change those behaviors.
- Visual surfaces re-use existing `AppColors` tokens, Inter typography, gradient surfaces, and soft 1-px borders. NO new color, NO new font, NO new shadow tokens. The status-badge color contract is documented inline in design under "Visual Design Notes".
- The Public Booking Form is the only screen in this slice that runs unauthenticated. Its provider tree is isolated from the session tree; the route is non-auth-guarded.
- Bengali numerals on every booking surface are Property-tested (P12); the `BookingFormat` helpers MUST be used everywhere a numeric value is rendered. UI code that interpolates numbers directly into strings without going through `BookingFormat` will fail the P12 property test.

---

## Task Dependency Graph

Waves are scheduled to maximize parallelism. Tasks within the same wave are independent; tasks in later waves depend on at least one task from an earlier wave.

```json
{
  "waves": [
    { "id": 0,  "tasks": ["0.1", "0.2", "0.3"] },
    { "id": 1,  "tasks": ["1.1"] },
    { "id": 2,  "tasks": ["1.2"] },
    { "id": 3,  "tasks": ["1.3", "2.1", "2.2", "2.3", "3.1", "3.3", "4.1"] },
    { "id": 4,  "tasks": ["1.4", "2.4", "2.5", "3.2", "4.2", "4.3"] },
    { "id": 5,  "tasks": ["3.4", "4.4", "5.1", "5.2", "5.3", "5.4", "5.5", "5.6", "5.7", "5.8", "5.9"] },
    { "id": 6,  "tasks": ["5.10", "6.1"] },
    { "id": 7,  "tasks": ["6.2", "6.3", "6.4", "6.5", "6.6", "6.7", "6.8"] },
    { "id": 8,  "tasks": ["6.9"] },
    { "id": 9,  "tasks": ["6.10", "6.11", "6.12", "6.13", "6.14", "6.15", "6.16"] },
    { "id": 10, "tasks": ["7.1", "7.6"] },
    { "id": 11, "tasks": ["7.2", "7.3", "7.4", "7.5"] },
    { "id": 12, "tasks": ["7.7", "8.1", "8.2", "8.3", "8.4", "8.5", "8.6", "8.7"] },
    { "id": 13, "tasks": ["8.8"] },
    { "id": 14, "tasks": ["10.1", "10.2"] },
    { "id": 15, "tasks": ["10.3", "10.4"] },
    { "id": 16, "tasks": ["11.1", "11.2", "11.3", "11.4", "11.5", "11.6", "11.7", "11.8", "11.9", "11.10", "11.11", "11.12"] },
    { "id": 17, "tasks": ["12.1", "12.2", "12.3", "12.4", "12.5", "12.6"] },
    { "id": 18, "tasks": ["12.7", "13.1", "13.2", "13.3"] },
    { "id": 19, "tasks": ["13.4", "13.5", "14.1"] },
    { "id": 20, "tasks": ["14.2", "14.3", "14.4"] },
    { "id": 21, "tasks": ["15.1", "15.2", "15.3", "15.4", "15.5", "15.6", "15.7", "15.8", "15.9"] },
    { "id": 22, "tasks": ["15.10"] },
    { "id": 23, "tasks": ["15.11", "16.1", "16.2"] },
    { "id": 24, "tasks": ["17.1"] },
    { "id": 25, "tasks": ["17.2", "17.3", "17.4"] }
  ]
}
```
