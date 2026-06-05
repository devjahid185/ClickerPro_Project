# Requirements Document

> **Spec:** `bookings-module` · **Workflow:** Requirements-First
> **Phase:** Phase 2 — Operations slice
> **Modules covered:** MOD-07 Booking List, MOD-08 Booking Create/Edit, MOD-09 Calendar View, plus Booking Detail, Status Flow, Public Client Booking, Re-edit Requests, Task Progress
> **Builds on:** `foundation-mvp` (ApiClient, SecureStore, Outbox queue, Drift database, Riverpod tree, Dark Luxury Lens theme, ARB i18n, Role_Policy, Outbox_Worker)
> **Architecture source:** `Clicker_Pro_Architecture_v6_2.html` — MOD-07, MOD-08, MOD-09
> **Backend:** Node.js + Express 5 + Prisma 5 + PostgreSQL — full schema for `Event`, `Client`, `Assignment`, `Payment`, `Invoice`, `Package`, `StatusHistory`, `ReEditRequest`, `TaskProgress`, `Notification`, `Broadcast` already present at `backend/prisma/schema.prisma`; controller stubs exist for `bookingController`, `clientController`, `assignmentController`, `paymentController`, `packageController`, `statusController`, `reeditController`, `taskController`, `clientBookingController`.

---

## Introduction

The Bookings Module is the operational core of Clicker Pro: the place where photography studios capture every event, schedule their team, track progress, collect payments, and answer client requests. After Foundation MVP shipped the runtime backbone (auth, profile, settings, dashboard, theme, ARB, Drift, Outbox), this module plugs the first real business workflow into that backbone.

The slice covers nine workflows — list, calendar, create/edit, detail, status state machine, public client booking request, re-edit request, per-staff task progress, and offline-first sync — wired into the existing Drift database, the existing Outbox queue, the existing Role_Policy, the existing ApiClient, and the existing ARB-driven bilingual system. No new colors, no new fonts, no new Outbox mechanism — only new tables, new domain models, new repositories, new providers, new screens, and new ARB keys.

Visual surfaces follow the Dark Luxury Lens contract: `AppColors` tokens (Void Black, Signal Orange, Lens Gold, Indigo), Inter typography via `google_fonts`, gradient surfaces, soft 1-px borders, no glow effects. Number rendering follows the existing Bengali numerals helper when locale is `bn` and the toggle is on. Every screen renders one of the four shared async states (LensLoader / EmptyState / ErrorState / OfflineBanner).

This document captures **what the system shall do**. The **how** lives in `design.md`. Every Correctness Property in the design must trace back to at least one acceptance criterion below via a `Validates: Requirements X.Y` reference.

---

## Glossary

- **Event** — A scheduled photography engagement (Wedding, Holud, Birthday, Corporate, Pre-wedding, or Other custom). Stored in Drift `BookingsTable` and Postgres `Event`. Synonyms: *booking*, *gig*. Used interchangeably with **Booking**.
- **Booking** — Public-facing label for an Event in the UI. Identical entity.
- **EventType** — One of `wedding | holud | birthday | corporate | preWedding | other`. The type drives which optional fields render (e.g., bride/groom names appear only for `wedding` and `holud`).
- **EventStatus** — One of `pending | confirmed | inProgress | shotComplete | delivered | completed | cancelled`. Drives UI badge color and gates allowed transitions.
- **Shift** — One of `day | night | both`. Used for venue and team scheduling.
- **Client** — A person or organization for whom an Event is booked. Stored in Drift `ClientsTable` and Postgres `Client`. Holds name, phone, email, address, DOB, anniversary.
- **Assignment** — A staff-to-event link with a role and a payout amount. Stored in Drift `AssignmentsTable` and Postgres `Assignment`.
- **AssignmentRole** — One of `photographer | cinematographer | editor | assistant | drone`. Drives the Assignment row label and quick-filter chips.
- **Payment** — A money movement against an Event: `advance`, `due`, or `extra`. Stored in Drift `PaymentsTable` and Postgres `Payment`.
- **Package** — A reusable price+coverage bundle attachable to an Event. Stored in Drift `PackagesTable` and Postgres `Package`.
- **StatusHistory** — An append-only log of every status transition for an Event with `changedBy`, `at`, `note`, `fromStatus`, `toStatus`. Stored in Drift `StatusHistoryTable` and Postgres `StatusHistory`.
- **ReEditRequest** — A client-originated request for an additional editing round (round 1, 2, etc.) on a delivered Event with editor, deadline, reference images, and status.
- **ReEditStatus** — One of `pending | inProgress | done | rejected`.
- **TaskProgress** — A per-staff per-event progress percentage and freeform note, updated by the assigned staff member.
- **Public Booking Token** — A signed, single-purpose, expiring URL token that lets a non-authenticated client submit an Event request. Server-issued; client-validated.
- **Public Booking Request** — The pending Event submitted via the Public Booking Token, awaiting Owner approval.
- **Booking_List_Screen** — The screen at `RouteNames.bookings`. Lists Events with filters, search, sort, and lazy pagination.
- **Booking_Edit_Screen** — The screen at `RouteNames.bookingEdit` (and `bookingNew` for a fresh draft). Combined create + edit form.
- **Booking_Detail_Screen** — The screen at `RouteNames.bookingDetail`. Read-only view with edit affordance for permitted roles.
- **Calendar_Screen** — The screen at `RouteNames.calendar`. Monthly grid with status-colored dots.
- **Public_Booking_Form** — The screen at `RouteNames.publicBooking`, accessible without authentication via a `?token=...` query param.
- **ReEdit_Request_Screen** — The screen at `RouteNames.reEditRequest`. Owner/Manager view of all re-edit requests; client-side submission flows from Booking_Detail_Screen.
- **Booking_Repository** — Domain-layer contract owning Event reads/writes, watching, and remote sync.
- **Client_Repository** — Domain-layer contract owning Client reads/writes and search-by-phone.
- **Assignment_Repository** — Domain-layer contract owning Assignment CRUD per Event.
- **Payment_Repository** — Domain-layer contract owning Payment CRUD per Event and aggregate computations (advance / due / total).
- **Package_Repository** — Domain-layer contract owning Package CRUD.
- **Status_Repository** — Domain-layer contract owning StatusHistory append and current-status reads.
- **ReEdit_Repository** — Domain-layer contract owning ReEditRequest CRUD.
- **Task_Repository** — Domain-layer contract owning TaskProgress CRUD per assignment.
- **Public_Booking_Repository** — Domain-layer contract owning the unauthenticated public-booking flow (token validate, submit request, list pending for Owner approval).
- **Booking_Status_Machine** — The pure function that decides whether a `(role, currentStatus, targetStatus)` transition is allowed.
- **Capability** — A discrete, named UI/data action gated by Role_Policy. Defined in Foundation MVP. This module adds the booking-specific capabilities listed in Requirement 11.
- **Outbox_Queue** — The local queue of pending mutations; defined in Foundation MVP. This module extends its supported entity types.
- **Bengali_Numerals_Helper** — The `formatNumber` helper from Foundation MVP that renders digits in U+09E6 through U+09EF when `locale == 'bn'` AND the Bengali numerals toggle is on.
- **Hide_Payment_Flag** — The per-event `hidePaymentFromTeam` boolean controlled by an Owner toggle on Booking_Edit_Screen. When true, Manager and Freelancer roles SHALL not see payment or payout fields for that Event.
- **EARS** — Easy Approach to Requirements Syntax. Every acceptance criterion uses one of the six EARS patterns: ubiquitous (`THE … SHALL …`), event-driven (`WHEN …, THE … SHALL …`), state-driven (`WHILE …, THE … SHALL …`), unwanted-event (`IF …, THEN THE … SHALL …`), optional-feature (`WHERE …, THE … SHALL …`), or complex.

---

## Requirements

### Requirement 1: Booking List (MOD-07)

**User Story:** As an authenticated user, I want a single list of every Event I am allowed to see, with filters, search, sort, and lazy pagination, so that I can quickly find any booking across hundreds of past and future engagements.

#### Acceptance Criteria

1. WHEN a user opens Booking_List_Screen, THE Booking_Repository SHALL return Events filtered by the active role scope where role scope is defined as: Owner or Both → all Events for the user's studio; Manager → Events whose `studioId` equals the Manager's `ownerId` AND that have at least one Assignment to the Manager OR whose `createdBy` equals the Manager's id; Freelancer → Events whose `createdBy` equals the user's id OR that have at least one Assignment to the user.
2. WHEN Booking_List_Screen renders the result list, THE screen SHALL render exactly one of the four shared async states {LensLoader, EmptyState, ErrorState, content} per the Foundation MVP state contract.
3. THE Booking_List_Screen filter bar SHALL expose four filter controls: date range (from + to), status (multi-select over `EventStatus`), event type (multi-select over `EventType`), and client (single-select autocomplete over Client).
4. WHEN a user changes any filter control value, THE Booking_List_Screen SHALL re-query the Booking_Repository AND emit a new result list within 200 milliseconds for a result set of up to 200 Events.
5. WHEN a user types in the search field, THE Booking_List_Screen SHALL debounce input changes by 300 milliseconds AND query the Booking_Repository with a query that matches against the Event title, the linked Client's name, the linked Client's phone, and the venue.
6. THE Booking_List_Screen sort control SHALL expose four sort orders: `dateDesc` (default), `dateAsc`, `createdAtDesc`, `clientNameAsc`.
7. WHEN a user scrolls within 200 logical pixels of the bottom of the list AND more results exist on the server, THE Booking_List_Screen SHALL trigger the next page request via Booking_Repository AND append the returned page to the existing list.
8. THE Booking_List_Screen SHALL paginate at a page size of 20 Events per request.
9. WHEN a user taps an Event row, THE Booking_List_Screen SHALL navigate to Booking_Detail_Screen for that Event by its local id via the central app router.
10. WHEN the active language changes, THE Booking_List_Screen SHALL re-render every visible label in the new locale within one frame.
11. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE Booking_List_Screen SHALL render every numeric value (date day, year, list count, page count, payment amounts) using Bengali_Numerals_Helper.
12. WHEN connectivity is offline, THE Booking_List_Screen SHALL render the OfflineBanner AND THE list SHALL display the last cached page from the local Drift store; WHILE connectivity is online but the server is unreachable (network reachable but API requests fail), THE Booking_List_Screen SHALL NOT fall back to cached data AND SHALL surface the structured error via ErrorState.
13. THE Booking_List_Screen SHALL render a status badge on every list row using the status-color contract: `pending → indigo`, `confirmed → orange`, `inProgress → orange`, `shotComplete → gold`, `delivered → gold`, `completed → green-bnw`, `cancelled → red`.
14. THE Booking_List_Screen SHALL render a "+" floating action button that, on tap, navigates to a fresh Booking_Edit_Screen via the central app router.

---

### Requirement 2: Booking Create / Edit (MOD-08)

**User Story:** As a user with the appropriate role, I want a single form for creating and editing an Event with every operational field, so that I can capture all booking detail in one place without navigating through multiple screens.

#### Acceptance Criteria

1. WHEN a user opens Booking_Edit_Screen with no Event id, THE Booking_Edit_Screen SHALL render a fresh draft AND THE form SHALL contain a Title input, an EventType selector, a Date input, a StartTime input, an EndTime input, a Shift selector, a Venue input, an Outdoor checkbox, a Client picker, a Package picker (or custom price input), a Coverage hours input, an Extra hour rate input, a Drive link input, a Client requirements freeform input, a Notes input, a Chief photographer picker, a Chief hours input, an Assignments list editor, and a Hide-payment-from-team toggle.
2. WHILE THE EventType selector value is `wedding` OR `holud`, THE Booking_Edit_Screen SHALL display a Bride name input AND a Groom name input; WHILE THE EventType selector value is in `{birthday, corporate, preWedding, other}`, THE Booking_Edit_Screen SHALL hide both inputs.
3. WHEN a user submits Booking_Edit_Screen with all required fields valid (Title length 1–120, Date present, StartTime present, EndTime ≥ StartTime, Client selected, EventType selected), THE Booking_Repository SHALL persist the Event to the local Drift store with `pending=true` AND enqueue the create or update mutation in Outbox_Queue AND THE Booking_Edit_Screen SHALL navigate back to Booking_Detail_Screen for the new Event within one frame.
4. IF any required field validator fails, THEN THE Booking_Edit_Screen SHALL remain on the form AND render the validation error inline beside the offending field AND no network request SHALL be issued.
5. WHEN a user opens Booking_Edit_Screen with an existing Event id AND THE current user satisfies `Role_Policy.can(Capability.editBooking)`, THE Booking_Edit_Screen SHALL load the Event from the local Drift store within one frame AND populate every field from the Event AND each linked Assignment, Payment, and Client record.
6. IF a user opens Booking_Edit_Screen with an existing Event id AND THE current user does NOT satisfy `Role_Policy.can(Capability.editBooking)`, THEN THE central app router SHALL redirect to Booking_Detail_Screen for that Event.
7. THE Client picker SHALL support either selecting an existing Client by phone-number autocomplete OR creating a new Client inline by submitting `{name, phone, email?, address?, dob?, anniversary?}` where name length is 1–80 and phone is a non-empty digit string.
8. THE Package picker SHALL support either selecting an existing Package OR entering a custom price as a positive decimal; WHEN a Package is selected, THE Booking_Edit_Screen SHALL pre-fill the coverage hours input and the price field from the Package.
9. THE Assignments list editor SHALL support adding, editing, and removing rows where each row contains a staff picker (constrained to studio team members for Owner/Manager OR self-only for Freelancer), an AssignmentRole selector, and a Payout amount input ≥ 0.
10. WHERE THE current user satisfies `Role_Policy.can(Capability.toggleHidePayment)` (Owner or Both only), THE Booking_Edit_Screen SHALL display the Hide-payment-from-team toggle; WHERE the current user does NOT satisfy that capability, THE toggle SHALL be hidden AND its persisted value SHALL remain unchanged on save.
11. WHEN a user enters a Drive link, THE Booking_Edit_Screen SHALL validate that the input is either empty OR matches the URL pattern starting with `https://drive.google.com/` or `https://docs.google.com/` AND reject other strings inline.
12. WHEN Booking_Edit_Screen is in edit mode AND a remote update for the same Event arrives via background sync, THE Booking_Edit_Screen SHALL preserve the user's unsaved local edits AND surface a non-blocking SnackBar indicating that newer remote data is available with a "Reload" action.
13. THE Booking_Edit_Screen SHALL support cancelling the form via a Cancel control that, if there are unsaved changes, opens a confirm dialog before discarding the draft AND no network request SHALL be issued on cancel.
14. WHEN the active language changes while Booking_Edit_Screen is visible, THE screen SHALL re-render every visible label and validator message in the new locale within one frame.

---

### Requirement 3: Status Flow State Machine

**User Story:** As a user with role-appropriate permissions, I want every booking status change to follow a defined transition flow with a logged history, so that the team has a single source of truth for "where is this booking right now".

#### Acceptance Criteria

1. THE Booking_Status_Machine SHALL define forward transitions exactly as: `pending → confirmed`, `confirmed → inProgress`, `inProgress → shotComplete`, `shotComplete → delivered`, `delivered → completed`.
2. THE Booking_Status_Machine SHALL define a cancel transition from any status in `{pending, confirmed, inProgress, shotComplete, delivered}` to `cancelled` AND SHALL NOT allow `cancelled → *`.
3. THE Booking_Status_Machine SHALL NOT allow any transition not enumerated in Acceptance Criteria 3.1 or 3.2.
4. WHEN a user with role Owner or Both invokes a status transition AND the transition is allowed by the Booking_Status_Machine, THE Status_Repository SHALL append a StatusHistory row with `eventId`, `fromStatus`, `toStatus`, `changedByUserId`, `at = now`, and the user-supplied `note?` AND update the Event's current status AND enqueue the update in Outbox_Queue.
5. WHEN a user with role Manager invokes a forward transition (any transition in 3.1) AND the transition is allowed, THE Status_Repository SHALL perform the same actions as in 3.4.
6. IF a user with role Manager invokes the cancel transition (any transition in 3.2), THEN THE Booking_Status_Machine SHALL reject the action AND THE Booking_Detail_Screen SHALL hide the Cancel control for Manager.
7. IF a user with role Freelancer invokes any Event-level status transition, THEN THE Booking_Status_Machine SHALL reject the action AND THE Booking_Detail_Screen SHALL hide every Event-level status control for Freelancer.
8. WHEN a user invokes the cancel transition, THE Booking_Detail_Screen SHALL require a non-empty cancellation reason of length 1–500 characters AND THE Status_Repository SHALL persist that reason as the StatusHistory `note`.
9. THE Booking_Detail_Screen SHALL render a status timeline component that lists every StatusHistory row in ascending order of `at`, each rendered with `fromStatus → toStatus`, `changedByUserId → display name`, formatted timestamp, and the optional note.
10. WHEN a status transition is enqueued in Outbox_Queue AND has not yet been confirmed by the server, THE timeline row SHALL render a pending indicator (small orange dot) until Outbox_Worker reports a successful sync.
11. IF a status transition request returns an HTTP 409 Conflict from the server (server's current status differs from the client's expected `fromStatus`), THEN THE Status_Repository SHALL revert the local status to the server's reported value AND surface a non-blocking error to the user requesting they reload the Event.

---

### Requirement 4: Calendar View (MOD-09)

**User Story:** As a user, I want a monthly calendar view showing every Event I'm allowed to see as colored dots on their dates, so that I can plan around busy periods at a glance.

#### Acceptance Criteria

1. WHEN a user opens Calendar_Screen, THE Calendar_Screen SHALL render a monthly grid for the current month with every day cell labeled by its day-of-month number.
2. WHEN Calendar_Screen renders Events, THE Calendar_Screen SHALL fetch Events whose date falls within the visible month from Booking_Repository scoped per Requirement 1.1 AND render up to three colored dots per day cell, one dot per Event, colored by EventStatus per the status-color contract in Requirement 1.13.
3. WHILE more than three Events fall on the same day, THE day cell SHALL render three dots plus a `+N` overflow indicator where `N` is the count of Events beyond the third.
4. WHEN a user taps a day cell, THE Calendar_Screen SHALL display a day-events bottom sheet listing every Event for that day, ordered by start time ascending.
5. WHEN a user taps an Event row in the day-events bottom sheet, THE Calendar_Screen SHALL navigate to Booking_Detail_Screen for that Event via the central app router.
6. WHEN a user taps the next-month or previous-month control, THE Calendar_Screen SHALL transition the visible month within 280 milliseconds (a transition that takes exactly 280 milliseconds is allowed) AND re-query Events for the new month.
7. THE Calendar_Screen SHALL expose an Add control that navigates to a fresh Booking_Edit_Screen with the currently selected day pre-filled as the Event date.
8. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE Calendar_Screen SHALL render every day-of-month number, every overflow `+N` indicator, and every year using Bengali_Numerals_Helper.
9. WHEN the active language changes, THE Calendar_Screen SHALL re-render the month-name header and every weekday header in the new locale within one frame.
10. WHEN connectivity is offline, THE Calendar_Screen SHALL render the OfflineBanner AND continue rendering Events from the last cached month in the local Drift store; WHILE connectivity is online, THE Calendar_Screen MAY render Events from the local Drift store cache while a fresh fetch is in flight AND SHALL replace cached Events with fresh data once the fetch completes.

---

### Requirement 5: Booking Detail Screen

**User Story:** As a user with permission to view a booking, I want a single read-only screen that shows everything about the Event — client info, schedule, package, payments, assignments, status history, attachments — so that I can answer any question about it without editing anything by accident.

#### Acceptance Criteria

1. WHEN a user opens Booking_Detail_Screen for an Event id, THE Booking_Detail_Screen SHALL load the Event from the local Drift store within one frame AND trigger Booking_Repository.refreshFromRemote for that Event id in the background.
2. THE Booking_Detail_Screen SHALL render the following sections in order: Header (title, status badge, type, date/time/shift), Client info (name, phone, email, address; bride/groom names if EventType ∈ `{wedding, holud}`), Schedule (venue, outdoor flag, coverage hours, extra hour rate), Package (name + price OR custom price + drive link), Payment summary (advance + due + extra + total), Assignments list (staff name, role, payout), Status timeline, Re-edit requests, Attachments and Notes, Client requirements.
3. WHERE THE current user satisfies `Role_Policy.can(Capability.viewBookingPayments)` AND the Hide_Payment_Flag for this Event is `false`, THE Booking_Detail_Screen SHALL render the Payment summary section AND the Payout column of the Assignments list.
4. WHERE THE current user does NOT satisfy `Role_Policy.can(Capability.viewBookingPayments)` OR the Hide_Payment_Flag is `true` AND the user's role is Manager or Freelancer, THE Booking_Detail_Screen SHALL hide the Payment summary section AND the Payout column from the Assignments list AND render an empty placeholder in their place.
5. WHERE THE current user satisfies `Role_Policy.can(Capability.editBooking)`, THE Booking_Detail_Screen SHALL render an Edit control in the app bar that navigates to Booking_Edit_Screen for the Event.
6. WHERE THE current user does NOT satisfy `Role_Policy.can(Capability.editBooking)`, THE Booking_Detail_Screen SHALL hide the Edit control.
7. WHEN a user with `Role_Policy.can(Capability.advanceBookingStatus)` taps the next-status action, THE Booking_Detail_Screen SHALL invoke the Status_Repository transition per Requirement 3.4 or 3.5 and render the optional note input.
8. WHEN a user with `Role_Policy.can(Capability.cancelBooking)` taps the Cancel action, THE Booking_Detail_Screen SHALL render the cancel-reason input AND on submit invoke the Status_Repository transition per Requirement 3.4.
9. THE Booking_Detail_Screen SHALL render the Drive link field as a tappable hyperlink that, on tap, opens the device's default browser with the URL.
10. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE Booking_Detail_Screen SHALL render every numeric value (date, time, hours, payment amounts, payout amounts) using Bengali_Numerals_Helper.
11. WHEN connectivity is offline, THE Booking_Detail_Screen SHALL render the OfflineBanner AND continue rendering the Event from the local Drift store.

---

### Requirement 6: Public Client Booking Form

**User Story:** As a studio Owner, I want to share a token URL with a prospective client so they can submit a booking request without signing up, so that I can capture leads from social media and chat conversations.

#### Acceptance Criteria

1. WHERE THE current user satisfies `Role_Policy.can(Capability.generatePublicBookingToken)` (Owner or Both only), THE Booking_List_Screen SHALL render a "Share booking link" control that, on tap, requests a Public Booking Token from the Public_Booking_Repository AND surfaces the resulting URL in a share sheet.
2. THE Public Booking Token URL SHALL have the format `https://<host>/public/booking?token=<token>` where the token is a server-issued, opaque, single-purpose, time-limited string with a default expiry of 7 days from issuance.
3. WHEN an unauthenticated visitor opens the Public_Booking_Form with a `?token=` query parameter, THE Public_Booking_Form SHALL validate the token by calling the Public_Booking_Repository token-peek endpoint AND on a 200 response SHALL render the form bound to the issuing studio.
4. IF the token is invalid, expired, or already consumed beyond its allowed-uses limit, THEN THE Public_Booking_Form SHALL render a friendly error screen with a request-new-link instruction AND SHALL NOT allow form submission.
5. THE Public_Booking_Form SHALL collect the same minimal fields as Booking_Edit_Screen for Public Booking Requests: Title, EventType, Date, StartTime, EndTime, Shift, Venue, Bride name and Groom name (only if EventType ∈ `{wedding, holud}`), Client name, Client phone, Client email (optional), Notes (optional).
6. WHEN an unauthenticated visitor submits the Public_Booking_Form with all required fields valid AND a valid token, THE Public_Booking_Repository SHALL submit a Public Booking Request to the backend AND on a 201 response THE Public_Booking_Form SHALL render a success confirmation screen.
7. WHERE THE current user satisfies `Role_Policy.can(Capability.approvePublicBooking)` (Owner or Both only), THE Booking_List_Screen SHALL render a "Pending requests" entry in the filter bar that, when active, surfaces every Public Booking Request awaiting approval for the user's studio.
8. WHEN a user with approval capability taps Approve on a Public Booking Request, THE Public_Booking_Repository SHALL transition the request to a real Event with status `pending` AND link the linked Client (creating a Client row by phone match if necessary) AND remove the request from the pending list.
9. WHEN a user with approval capability taps Reject on a Public Booking Request, THE Public_Booking_Repository SHALL transition the request to `rejected` AND remove it from the pending list AND surface a non-blocking SnackBar.
10. THE Public_Booking_Form SHALL render in the locale specified by the token's issuing studio (defaulting to `en`) AND SHALL apply the existing Dark Luxury Lens theme contract.
11. IF the unauthenticated visitor submits the Public_Booking_Form while offline, THEN THE Public_Booking_Form SHALL render an inline error indicating that an internet connection is required AND SHALL NOT enqueue the request locally.

---

### Requirement 7: Re-edit Request

**User Story:** As a client (or as a studio Owner submitting on a client's behalf), I want to request additional editing rounds on a delivered event with reference images and a deadline, so that we can iterate on photos and videos until they're right.

#### Acceptance Criteria

1. WHILE THE Event status is in `{shotComplete, delivered, completed}`, THE Booking_Detail_Screen SHALL render a "Request Re-edit" control accessible to roles that satisfy `Role_Policy.can(Capability.requestReEdit)` (Owner, Both, Manager).
2. WHEN a user invokes Request Re-edit, THE Booking_Detail_Screen SHALL render a form with: Round number (auto-incremented from existing rounds for this Event, starting at 1), Editor picker (constrained to staff with AssignmentRole `editor` on this Event OR any studio editor for Owner/Both), Deadline date input, Reference images (0–10 image attachments), and a Notes input (length 0–2000).
3. WHEN a user submits Request Re-edit with all required fields valid (Round ≥ 1, Editor selected, Deadline ≥ today), THE ReEdit_Repository SHALL persist the ReEditRequest with status `pending` to the local Drift store AND enqueue the create mutation in Outbox_Queue.
4. THE ReEditRequest entity SHALL track ReEditStatus values exactly: `pending | inProgress | done | rejected`.
5. WHILE THE current user is the assigned editor for a ReEditRequest, THE ReEdit_Request_Screen SHALL render Start (transitions `pending → inProgress`), Mark Done (transitions `inProgress → done`), and Reject (transitions `pending | inProgress → rejected`) controls.
6. WHEN a user transitions a ReEditRequest to `done`, THE ReEdit_Repository SHALL append a status entry with `at = now` AND THE Booking_Detail_Screen SHALL display the round as completed.
7. THE Booking_Detail_Screen Re-edit section SHALL list every ReEditRequest for the Event ordered by Round number ascending with their Round, status, editor, deadline, and a tap-to-expand block showing reference images and notes.
8. IF the deadline has passed AND status is in `{pending, inProgress}`, THEN THE ReEdit_Request_Screen SHALL render an "overdue" indicator (red border and label) on the request card.
9. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE ReEdit_Request_Screen SHALL render every Round number and every deadline day-of-month using Bengali_Numerals_Helper.
10. WHERE THE current user does NOT satisfy `Role_Policy.can(Capability.requestReEdit)`, THE Booking_Detail_Screen SHALL hide the Request Re-edit control AND render the existing re-edit history read-only.

---

### Requirement 8: Task Progress

**User Story:** As an assigned staff member, I want to update my own per-event progress with a percentage and a note, so that the Owner and Manager can see how each piece of work is moving without messaging me.

#### Acceptance Criteria

1. WHILE THE current user has at least one Assignment to the Event, THE Booking_Detail_Screen SHALL render a "My Progress" section showing the user's current TaskProgress percentage (0–100) and most recent note.
2. WHEN a user invokes Update Progress, THE Booking_Detail_Screen SHALL render an inline editor with a percentage slider (0–100, step 5) and a Notes input (length 0–500).
3. WHEN a user submits the Update Progress form, THE Task_Repository SHALL upsert a TaskProgress row keyed by `(eventId, userId, assignmentId)` with `percentage`, `note`, `updatedAt = now` AND enqueue the update in Outbox_Queue.
4. WHERE THE current user's role is Owner, Both, or Manager, THE Booking_Detail_Screen SHALL render an "All Progress" section listing every TaskProgress row for the Event with the assigned staff name, AssignmentRole, percentage, last note, and last updatedAt.
5. WHERE THE current user's role is Freelancer, THE Booking_Detail_Screen SHALL hide the "All Progress" section AND only render the user's own "My Progress" section.
6. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE Task progress sections SHALL render every percentage value using Bengali_Numerals_Helper followed by the literal `%` glyph (which remains the Latin percent sign in both locales).
7. WHEN a TaskProgress row is updated, THE Booking_Detail_Screen SHALL re-render the corresponding row within one frame.

---

### Requirement 9: Status History Timeline

**User Story:** As any user with permission to view a booking, I want a visual timeline of every status transition with who did it, when, and why, so that I can audit how a booking moved through its lifecycle.

#### Acceptance Criteria

1. THE Booking_Detail_Screen Status History section SHALL render every StatusHistory row for the Event in ascending order of `at`, formatted as a vertical timeline with each row showing `fromStatus → toStatus`, the actor's display name, the formatted timestamp, and the optional note (truncated to 120 characters with a "more" affordance to expand).
2. WHEN a StatusHistory row's `at` is within 24 hours of `now` (a row exactly at the 24-hour boundary is treated as within), THE timeline SHALL render the timestamp using a relative format (e.g., "2 hours ago"); otherwise THE timeline SHALL render the timestamp using an absolute locale-aware date+time format.
3. WHILE Outbox_Queue contains a pending status transition for the Event, THE timeline SHALL render that transition with a pending indicator (small orange dot) until Outbox_Worker reports a successful sync.
4. IF a StatusHistory row's `note` is empty, THEN THE timeline SHALL render the row without a note slot AND SHALL NOT render an empty quote-style placeholder.
5. WHERE THE Event status is `cancelled`, THE timeline SHALL render the cancellation row with a red status indicator AND surface the cancellation reason as the note expanded by default.
6. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, THE timeline SHALL render every numeric value (year, day-of-month, hour, minute) using Bengali_Numerals_Helper.

---

### Requirement 10: Offline-First Booking Sync

**User Story:** As a user shooting a wedding in a venue with no signal, I want to create bookings, change status, log payments, and update progress while offline and have everything sync when I'm back online, so that the network never blocks my work.

#### Acceptance Criteria

1. WHEN a user invokes any of {create Event, edit Event, change status, add/edit/remove Assignment, add Payment, request Re-edit, update Task Progress} while offline, THE corresponding repository SHALL commit the change to the local Drift store with `pending=true` BEFORE attempting any network call.
2. WHEN the network call fails due to a network error, a request timeout, or a 5xx response, THE corresponding mutation SHALL remain intact in the local Drift store AND be enqueued in Outbox_Queue with the entity type {`booking`, `client`, `assignment`, `payment`, `package`, `statusHistory`, `reEditRequest`, `taskProgress`}, the local entity id, the operation (`create`, `update`, `delete`), and a JSON payload.
3. WHILE connectivity is online AND Outbox_Queue contains pending booking-related items, THE Outbox_Worker SHALL drain those items in FIFO order using the same exponential backoff schedule defined in Foundation MVP (initial delay 2 seconds, doubling on each failure, capped at 300 seconds between attempts).
4. WHEN a queued mutation succeeds (HTTP 2xx), THE Outbox_Worker SHALL remove the corresponding OutboxItem AND mark the local row as synchronized AND replace the local id with the server-issued remote id where applicable.
5. IF a queued mutation has failed 5 consecutive times, THEN THE Outbox_Worker SHALL stop automatic retry for that OutboxItem AND mark it as requiring manual retry AND surface a sync-error indication via the existing top-bar sync status indicator.
6. WHEN a remote update for an Event, Client, Assignment, Payment, Package, or TaskProgress arrives concurrent with a pending local change for the same entity, THE Outbox_Worker SHALL apply the last-write-wins conflict tier using the most recent `updatedAt` timestamp.
7. WHEN a remote update for a StatusHistory row arrives, THE Outbox_Worker SHALL append it to the local store AND SHALL NOT overwrite any local StatusHistory row (StatusHistory is append-only).
8. WHEN a status-transition mutation drains AND the server returns HTTP 409 Conflict (the server's current status differs from the client's expected `fromStatus`), THE Outbox_Worker SHALL drop the local status change AND adopt the server's reported status AND surface a non-blocking error to the user requesting they reload the Event per Requirement 3.11.
9. WHEN connectivity transitions from offline to online, THE Booking_Repository SHALL trigger a background refresh of the visible page of Events.
10. WHEN a user logs out, THE Outbox_Queue SHALL preserve every queued booking-related item associated with the user AND resume drain attempts when the user re-authenticates with the same account on the same device.

---

### Requirement 11: Role-Adaptive UI for Bookings

**User Story:** As a user of any role, I want every booking screen to show only the data and controls my role permits, so that I see information I need without seeing data I should not.

#### Acceptance Criteria

1. THE Role_Policy SHALL be extended with the following booking-specific Capabilities: `viewAllBookings`, `viewAssignedBookings`, `viewOwnBookings`, `createBooking`, `editBooking`, `deleteBooking`, `advanceBookingStatus`, `cancelBooking`, `viewBookingPayments`, `viewBookingPayouts`, `editBookingPayments`, `editAssignment`, `toggleHidePayment`, `generatePublicBookingToken`, `approvePublicBooking`, `requestReEdit`, `assignReEdit`, `updateTaskProgress`.
2. THE Role_Policy capability matrix SHALL include the following bindings — Owner: every booking-specific capability; Both: every booking-specific capability; Manager: `viewAssignedBookings`, `createBooking`, `editBooking`, `advanceBookingStatus`, `viewBookingPayments` (subject to Hide_Payment_Flag), `viewBookingPayouts` (subject to Hide_Payment_Flag), `editAssignment`, `requestReEdit`, `updateTaskProgress`; Freelancer: `viewOwnBookings`, `updateTaskProgress`, `requestReEdit` (only on own bookings).
3. WHERE THE current user's role is Manager AND THE Hide_Payment_Flag for an Event is `true`, THE Booking_Detail_Screen SHALL hide the Payment summary section AND the Assignments list Payout column for that Event AND THE Booking_List_Screen SHALL hide the per-row payment subtitle for that Event.
4. WHERE THE current user's role is Freelancer, THE Booking_Detail_Screen SHALL render the Assignments list filtered to show only the Freelancer's own Assignment row AND its payout AND SHALL hide other staff Assignments AND their payouts.
5. WHERE THE current user's role is Freelancer, THE Booking_List_Screen SHALL filter the list to Events satisfying the Freelancer scope per Requirement 1.1 AND THE Calendar_Screen SHALL apply the same filter.
6. WHEN a user invokes a booking action (create, edit, status transition, cancel, etc.), THE Booking_Repository (or relevant repository) SHALL verify the action against `Role_Policy.can(...)` BEFORE issuing any network call AND SHALL throw a typed `RolePolicyDeniedException` if denied.
7. WHEN the current user's role changes, THE Booking_List_Screen, Booking_Detail_Screen, Booking_Edit_Screen, and Calendar_Screen SHALL each rebuild with the updated capability gating within one frame of the next read of `rolePolicyProvider`.

---

### Requirement 12: Bilingual Booking UI

**User Story:** As a Bengali- or English-speaking user, I want every booking surface to honor my language, including all numeric values when Bengali numerals are enabled, so that my full workflow is in my language.

#### Acceptance Criteria

1. THE ARB files `app_en.arb` and `app_bn.arb` SHALL be extended with at minimum a `bookings` namespace containing keys for every visible label in Booking_List_Screen, Booking_Edit_Screen, Booking_Detail_Screen, Calendar_Screen, Public_Booking_Form, ReEdit_Request_Screen, status-machine error messages, and validation error messages.
2. FOR every translation key added in this slice, THE bn ARB file SHALL contain a non-empty Bengali translation AND THE en ARB file SHALL contain the corresponding English source string.
3. WHEN the active language changes at runtime, every booking screen SHALL rebuild every visible string in the new locale within one frame.
4. WHILE the active locale is `bn` AND the Bengali numerals toggle is on, every booking screen SHALL render every numeric value (Event count, page count, day-of-month, year, hour, minute, percentage, payment amount, payout amount, coverage hours, extra hour rate, package price) using Bengali_Numerals_Helper.
5. WHILE the active locale is `bn`, every booking screen SHALL apply the Noto Sans Bengali typeface fallback via the existing theme `_bnAware` helper from Foundation MVP.
6. THE date-picker AND the time-picker components used in Booking_Edit_Screen, Calendar_Screen, and Public_Booking_Form SHALL respect the active locale AND format dates and times using locale-aware formatters.
7. IF a translation key added in this slice is missing in the active locale's ARB file at runtime, THEN THE Bilingual_System SHALL fall back to the English value for that key.

---

### Requirement 13: Backend API Contract Alignment (Bookings Endpoints)

**User Story:** As a Flutter client developer, I want the client to invoke every backend bookings endpoint with the exact request shape and response handling specified, so that backend implementation gaps surface during development and the client is ready when each endpoint ships.

#### Acceptance Criteria

1. THE Clicker_Pro_Client SHALL invoke `GET /api/bookings` with query params `{from?, to?, status?, type?, clientId?, search?, sort?, page?, pageSize?}` AND the bearer token AND handle the 200 response containing `{ items, page, total }` AND surface a structured error on 4xx responses.
2. THE Clicker_Pro_Client SHALL invoke `GET /api/bookings/:id` with the bearer token AND handle the 200 response containing the full Event payload (event + client + assignments + payments + statusHistory + reEditRequests + taskProgress) AND surface a structured error on 4xx responses.
3. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings` with the Event creation payload AND the bearer token AND handle the 201 response containing the created Event AND surface a structured error on 4xx responses.
4. THE Clicker_Pro_Client SHALL invoke `PATCH /api/bookings/:id` with the partial Event payload AND the bearer token AND handle the 200 response containing the updated Event AND surface a structured error on 4xx responses.
5. THE Clicker_Pro_Client SHALL invoke `DELETE /api/bookings/:id` with the bearer token AND handle the 204 response AND surface a structured error on 4xx responses.
6. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings/:id/status` with body `{ toStatus, fromStatus, note? }` AND the bearer token AND handle the 200 response containing the updated Event AND treat HTTP 409 as a status-conflict signal per Requirement 3.11.
7. THE Clicker_Pro_Client SHALL invoke `GET /api/clients` and `POST /api/clients` and `PATCH /api/clients/:id` for Client CRUD AND handle the 200/201 responses AND surface structured errors on 4xx responses.
8. THE Clicker_Pro_Client SHALL invoke `GET /api/clients/search?phone=` for phone-prefix client autocomplete AND handle the 200 response containing `{ items }`.
9. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings/:id/assignments`, `PATCH /api/bookings/:id/assignments/:assignmentId`, and `DELETE /api/bookings/:id/assignments/:assignmentId` for Assignment CRUD AND surface structured errors on 4xx responses.
10. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings/:id/payments`, `PATCH /api/bookings/:id/payments/:paymentId`, and `DELETE /api/bookings/:id/payments/:paymentId` for Payment CRUD AND surface structured errors on 4xx responses.
11. THE Clicker_Pro_Client SHALL invoke `GET /api/packages`, `POST /api/packages`, `PATCH /api/packages/:id`, and `DELETE /api/packages/:id` for Package CRUD AND surface structured errors on 4xx responses.
12. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings/:id/reedits`, `PATCH /api/reedits/:reEditId/status`, and `GET /api/bookings/:id/reedits` for ReEditRequest workflow AND surface structured errors on 4xx responses.
13. THE Clicker_Pro_Client SHALL invoke `POST /api/bookings/:id/task-progress` (upsert) AND `GET /api/bookings/:id/task-progress` AND surface structured errors on 4xx responses.
14. THE Clicker_Pro_Client SHALL invoke `POST /api/team/public-booking-tokens` (Owner/Both, returns `{ token, url, expiresAt }`) AND `GET /api/public/booking?token=` (unauthenticated; returns issuing studio metadata) AND `POST /api/public/booking?token=` with the public booking payload (unauthenticated; returns 201 with the Public Booking Request id) AND surface structured errors on 4xx responses.
15. THE Clicker_Pro_Client SHALL invoke `GET /api/bookings/pending-public` (Owner/Both, returns the list of Public Booking Requests awaiting approval) AND `POST /api/bookings/pending-public/:requestId/approve` AND `POST /api/bookings/pending-public/:requestId/reject` AND surface structured errors on 4xx responses.
16. IF any endpoint listed in 13.1 through 13.15 returns a 4xx or 5xx response, THEN THE Clicker_Pro_Client SHALL surface a structured `ApiException` to the caller AND log the failure through the central app logger.
17. WHEN any endpoint listed above is invoked AND the network is unreachable or the request times out, THE Clicker_Pro_Client SHALL surface a network-level error AND THE caller SHALL render the OfflineBanner if applicable AND offline-capable mutations SHALL be enqueued in Outbox_Queue per Requirement 10.

---

### Requirement 14: Backend Controller Activation

**User Story:** As a developer responsible for keeping the backend and client honest, I want every booking-related backend controller currently shipped as a stub to have a real implementation that satisfies the API contract above, so that the Flutter client and the Postgres database are wired end-to-end.

#### Acceptance Criteria

1. THE backend `bookingController` SHALL implement list, get-by-id, create, update, delete, and status-transition handlers exactly per Requirement 13.1 through 13.6 AND SHALL apply the role-scope filter from Requirement 1.1 server-side.
2. THE backend `clientController` SHALL implement list, get-by-id, create, update, and phone-prefix search handlers exactly per Requirement 13.7 and 13.8.
3. THE backend `assignmentController` SHALL implement create, update, and delete handlers exactly per Requirement 13.9 AND SHALL enforce that an assignee belongs to the Owner's studio (or is the Owner/Freelancer themselves).
4. THE backend `paymentController` SHALL implement create, update, and delete handlers exactly per Requirement 13.10 AND SHALL maintain consistent advance/due/extra/total aggregates.
5. THE backend `packageController` SHALL implement list, create, update, and delete handlers exactly per Requirement 13.11 AND SHALL scope packages to the Owner's studio.
6. THE backend `statusController` SHALL implement the status-transition handler exactly per Requirement 13.6 AND SHALL enforce the Booking_Status_Machine transitions from Requirement 3.1 through 3.3 server-side AND return HTTP 409 if the supplied `fromStatus` does not match the server's current status for the Event.
7. THE backend `reeditController` SHALL implement create, list-by-event, and status-update handlers exactly per Requirement 13.12.
8. THE backend `taskController` SHALL implement upsert-task-progress and list-by-event handlers exactly per Requirement 13.13 AND SHALL enforce that the actor is an assignee on the Event for the upsert path.
9. THE backend `clientBookingController` SHALL implement public-token issuance, public-token peek, public-booking-request submission, pending-public list, approve, and reject handlers exactly per Requirement 13.14 and 13.15.
10. WHERE the backend uses Prisma and the schema already contains the required tables (per the project description), the implementations SHALL use the existing Prisma singleton AND SHALL NOT introduce a duplicate Prisma instance.
11. IF a request is missing required fields or supplies invalid types, THEN the backend handler SHALL respond with HTTP 400 AND a JSON body `{ error: { code, message, fields? } }`.
12. IF a request lacks a valid bearer token (for authenticated endpoints), THEN the backend handler SHALL respond with HTTP 401 AND a JSON body `{ error: { code: "UNAUTHORIZED", message } }`.
13. IF a request's user lacks the required role-policy capability for the action, THEN the backend handler SHALL respond with HTTP 403 AND a JSON body `{ error: { code: "FORBIDDEN", message } }`.
14. EVERY backend handler SHALL respond within 2 seconds for the 95th percentile of requests against a database of up to 1,000 Events, 5,000 Assignments, and 10,000 StatusHistory rows.

---

### Requirement 15: Conflict Resolution Rules

**User Story:** As a developer reasoning about offline edits, I want a single, written set of conflict-resolution rules per booking entity, so that every contributor knows what happens when the same row is edited locally and remotely.

#### Acceptance Criteria

1. THE conflict-resolution policy SHALL classify entities into three tiers: Tier A (last-write-wins by `updatedAt`), Tier B (server-wins on read; immutable client-side), Tier C (append-only).
2. Event, Client, Assignment, Payment, Package, and TaskProgress SHALL be Tier A.
3. Public Booking Token, Public Booking Request (server-issued metadata), and Studio team roster SHALL be Tier B.
4. StatusHistory and ReEditRequest status entries SHALL be Tier C.
5. WHEN Outbox_Worker drains a Tier A mutation AND the server's `updatedAt` is strictly newer than the client's `updatedAt`, THE Outbox_Worker SHALL discard the client's mutation AND surface a non-blocking SnackBar suggesting the user reload the Event.
6. WHEN Outbox_Worker drains a Tier A mutation AND the server's `updatedAt` equals the client's `updatedAt`, THE Outbox_Worker SHALL apply the client's mutation AND advance both timestamps.
7. WHEN Outbox_Worker drains a Tier A mutation AND the server's `updatedAt` is strictly older than the client's `updatedAt`, THE Outbox_Worker SHALL apply the client's mutation AND replace the server's row.
8. THE local Drift store SHALL store `updatedAt` for every Tier A row AND SHALL stamp it on every local write.
9. WHEN a Tier C row is enqueued in Outbox_Queue AND drains successfully, THE row SHALL be appended to the local store AND SHALL never be modified or deleted by future drains.

---

## Property → Requirements Traceability (informational)

The Correctness Properties in `design.md` map back to the acceptance criteria above. This table is informational; the canonical reference is the `**Validates: Requirements X.Y**` line under each property in the design document.

| Design Property | Validates Requirement(s) |
|---|---|
| Property 1: Booking_Status_Machine soundness | 3.1, 3.2, 3.3 |
| Property 2: Role-scoped booking visibility | 1.1, 11.5 |
| Property 3: Hide_Payment_Flag enforcement | 5.4, 11.3 |
| Property 4: Assignments scope per role | 11.4 |
| Property 5: Booking offline-write durability | 10.1, 10.2 |
| Property 6: Status-conflict 409 reconciliation | 3.11, 10.8 |
| Property 7: StatusHistory is append-only | 10.7, 15.4, 15.9 |
| Property 8: Last-write-wins by updatedAt | 10.6, 15.5, 15.6, 15.7 |
| Property 9: Round-trip booking serialization | 13.2, 13.3 |
| Property 10: Public Booking Token validity gate | 6.3, 6.4 |
| Property 11: Capability gating round-trip | 11.1, 11.2, 11.6 |
| Property 12: Bengali numerals coverage on bookings | 1.11, 4.8, 5.10, 7.9, 8.6, 9.6, 12.4 |
