# Requirements Document

> **Spec:** `foundation-mvp` · **Workflow:** Design-First (requirements derived from design)
> **Source design:** `.kiro/specs/foundation-mvp/design.md`
> **Architecture source of truth:** `Clicker_Pro_Architecture_v6_2.html` — Phase 1 Foundation slice
> **Modules covered:** MOD-01, MOD-02, MOD-03, MOD-04, MOD-05, MOD-06, MOD-48, MOD-49, MOD-50 (stub)

---

## Introduction

Clicker Pro is a bilingual (English / Bengali), role-adaptive, offline-first Flutter application for photographers in Bangladesh. The Foundation MVP slice delivers the runtime backbone every later phase will plug into: identity (login, register, OTP, forgot password, manager invite), splash and onboarding, role-adaptive profile and settings, real data wiring for the existing Dashboard and Navigation screens (visual unchanged), the Dark Luxury Lens theme contract, the ARB-based bilingual system, the in-app privacy/terms reader with a 7-day account-deletion grace window, and a Help & Support stub.

This document captures **what the system shall do**. The **how** lives in the design document. Every Correctness Property in the design must trace back to at least one acceptance criterion below via a `Validates: Requirements X.Y` reference. In addition to functional requirements, this document tracks (a) every defect identified in design §13 as a discrete acceptance criterion in Requirement 9, and (b) every backend endpoint in design §12 that the Flutter client must invoke per contract in Requirement 10 — including endpoints whose backend implementation may not yet exist, so backend gaps surface during development.

---

## Glossary

- **Owner** — User role for a studio operator. Can manage studio branding, finances, team invites, and distribution settings.
- **Freelancer** — User role for a solo photographer. Manages personal gear inventory and the list of companies they work with.
- **Both** — User role for a hybrid Owner+Freelancer. Inherits all Owner and Freelancer capabilities.
- **Manager** — User role for an Owner-invited team member. Cannot self-register, cannot change role, cannot edit studio branding. Created exclusively via the Accept Invite flow.
- **Session** — The authenticated state of the app, composed of a bearer token, a user profile, and an issued-at timestamp.
- **Session_Controller** — The component that owns the session lifecycle (restore on launch, login, logout, token validation, role change refresh).
- **Role_Policy** — The single source of truth for role-to-capability mapping. Exposes `can(Capability)` checks consumed by every screen.
- **Capability** — A discrete, named UI/data action gated by Role_Policy (e.g., editStudioBranding, viewFinancials, generateTeamInvite, deleteOwnAccount).
- **OutboxItem** — A pending local mutation queued for later remote synchronization.
- **Outbox_Queue** — The local queue of OutboxItem records awaiting remote sync.
- **Drift** — The local SQLite-backed source of truth used by the offline-first repositories.
- **ARB** — Application Resource Bundle. The ICU-style JSON localization file format consumed by Flutter `gen_l10n`. The slice ships `app_en.arb` and `app_bn.arb`.
- **Locale** — A Flutter `Locale` value identifying the active language. The slice supports `en` and `bn`.
- **Distribution** — An Owner/Both setting that toggles team revenue distribution behavior in finance modules (Phase 2 consumes the toggle; the slice only persists it).
- **Bilingual_System** — The component that owns the active Locale, translation lookups, Bengali numeral rendering, and Bengali typeface fallback.
- **Theme_System** — The component that owns the Dark Luxury Lens design tokens via `app_colors` and `app_theme`.
- **Splash_Controller** — The component that drives the launch animation and routes to the next screen based on onboarding flag and session state.
- **Onboarding_Controller** — The component that owns the language pre-pick screen, the 3-slide intro, and the `onboarding_complete` flag.
- **Auth_Service** — The component that fronts authentication endpoints (login, register, OTP, forgot/reset, accept-invite, change role, request/cancel delete, logout).
- **User_Repository** — The component that reads, writes, and watches the current user, gear inventory, and lifetime stats.
- **Preferences_Repository** — The component that reads, writes, and watches language, notification preferences, distribution toggle, and Bengali numerals.
- **Legal_Repository** — The component that fetches privacy and terms text, records consent, and submits data export requests.
- **Clicker_Pro_Client** — The Flutter application as a whole, used in requirements that span multiple subcomponents or describe end-to-end client behavior.
- **Password_Validator** — A reusable validator that accepts only passwords with length ≥ 8, containing at least one letter and at least one digit.
- **EARS** — Easy Approach to Requirements Syntax. Every acceptance criterion below uses one of: ubiquitous (`THE … SHALL …`), event-driven (`WHEN …, THE … SHALL …`), state-driven (`WHILE …, THE … SHALL …`), unwanted-event (`IF …, THEN THE … SHALL …`), optional-feature (`WHERE …, THE … SHALL …`), or complex (`[WHERE] [WHILE] [WHEN/IF] THE … SHALL …`).

---

## Requirements

### Requirement 1: Authentication & Session (MOD-01)

**User Story:** As a Clicker Pro user (Owner, Freelancer, Both, or Manager), I want to securely sign in, register, recover, and sign out, so that my professional data stays protected and accessible only to me across launches.

#### Acceptance Criteria

1. WHEN a user submits the login form with an email and password that match a registered active account in the backend, THE Auth_Service SHALL persist the returned bearer token to secure storage AND THE Session_Controller SHALL transition to the authenticated state with the returned user profile.
2. WHEN a user invokes Logout, THE Auth_Service SHALL clear the persisted bearer token AND clear the local user record AND THE Session_Controller SHALL transition to the unauthenticated state.
3. IF any authenticated API request returns HTTP 401, THEN THE Session_Controller SHALL transition to the unauthenticated state within one frame AND THE Clicker_Pro_Client SHALL route to the Login screen.
4. IF a registration request specifies role equal to Manager, THEN THE Auth_Service SHALL reject the request AND require the manager candidate to use the Accept Invite flow.
5. IF a Manager invokes the Change Role action, THEN THE Role_Policy SHALL deny the action AND THE Profile screen SHALL hide the Change Role control.
6. WHEN a user submits the Register form with role in {Owner, Freelancer, Both} AND name length is between 1 and 80 characters AND email matches a standard email format AND phone is a non-empty digit string AND password satisfies Password_Validator, THE Auth_Service SHALL create the account AND THE Session_Controller SHALL transition to the authenticated state with the new user.
7. WHEN a user requests an OTP for purpose in {signup, login, forgotPassword}, THE Auth_Service SHALL deliver a six-digit code to the supplied identifier AND set an expiry no longer than 10 minutes from issuance AND invalidate any previously issued unconsumed OTP for the same identifier and purpose.
8. WHEN a user submits an OTP code that matches the active code for the given identifier and purpose before expiry, THE Auth_Service SHALL return a valid session AND THE Session_Controller SHALL transition to the authenticated state.
9. IF a submitted OTP code is expired, already consumed, or does not match the active code, THEN THE Auth_Service SHALL reject the request AND THE OTP screen SHALL display an error message indicating that the code is invalid or expired.
10. WHEN a user submits the Forgot Password form with any syntactically valid email, THE Auth_Service SHALL respond with a generic acknowledgement that does not disclose whether the email is registered, AND IF the email matches a registered active account, THEN THE Auth_Service SHALL deliver a password-reset OTP to that email.
11. WHEN a user submits a valid password-reset token paired with a new password satisfying Password_Validator, THE Auth_Service SHALL update the password AND clear all active sessions for that account AND require the user to authenticate again before access is granted.
12. WHEN a Manager candidate submits a valid, unconsumed, unexpired six-digit invite code on the Accept Invite screen along with name, email, and a password satisfying Password_Validator, THE Auth_Service SHALL bind the new account to the issuing Owner's studio AND set the user's role to Manager AND THE Session_Controller SHALL transition to the authenticated state.
13. IF an invite code submitted on the Accept Invite screen is invalid, expired, or already consumed, THEN THE Auth_Service SHALL reject the request AND THE Accept Invite screen SHALL display "Invalid or expired code".
14. WHEN an Owner or Both user invokes Generate Invite, THE Auth_Service SHALL return a six-digit code with an expiry of 24 hours from issuance AND mark the code as single-use.
15. IF a Freelancer or Manager invokes Generate Invite, THEN THE Role_Policy SHALL deny the action AND THE control SHALL not be exposed in the user interface.
16. WHEN the application starts AND a bearer token exists in secure storage, THE Session_Controller SHALL validate the token by issuing a request to the profile endpoint with a 10-second timeout AND set the session to authenticated on a 200 response OR clear the token AND route to the Login screen on a 401 response or on a network failure or timeout.
17. WHILE the user is in the authenticated state, THE Auth_Service SHALL attach the bearer token to every outbound API request.
18. IF a user attempts to register with an email that is already registered, THEN THE Auth_Service SHALL return a duplicate-email error AND THE Register screen SHALL render the error inline on the email field.
19. IF a user submits the login form with credentials that do not match a registered active account, THEN THE Auth_Service SHALL reject the request AND THE Login screen SHALL display an error message indicating that the email or password is incorrect AND THE Session_Controller SHALL remain in the unauthenticated state.
20. IF a single identifier submits more than 5 OTP requests within a rolling 10-minute window, THEN THE Auth_Service SHALL reject further requests for that identifier within that window AND THE OTP screen SHALL display a rate-limit error message.

---

### Requirement 2: Onboarding & Language Pre-Pick (MOD-02 + MOD-48 first-launch)

**User Story:** As a first-time user, I want to choose my preferred language and see a brief introduction before I sign in, so that I understand the app and can use it in my language from the very first screen.

#### Acceptance Criteria

1. WHEN the application starts AND the onboarding-complete flag is false, THE Onboarding_Controller SHALL route to the Language Picker screen as the first screen presented after the Splash screen.
2. WHEN a user taps a language option in {en, bn} on the Language Picker screen, THE Bilingual_System SHALL apply the corresponding Locale within one frame AND THE Preferences_Repository SHALL persist the selected language code as the active language, replacing any previously selected value chosen on the same screen.
3. WHEN the user taps the Continue control on the Language Picker screen, THE Onboarding_Controller SHALL display the first slide of a three-slide introduction sequence.
4. WHEN the user taps the Done control on the third onboarding slide, THE Onboarding_Controller SHALL set the onboarding-complete flag to true AND route to the Login screen.
5. WHEN the application starts AND the onboarding-complete flag is true, THE Onboarding_Controller SHALL skip both the Language Picker screen and the introduction sequence.
6. WHEN the Splash animation completes, THE Splash_Controller SHALL route to the Language Picker screen if the onboarding-complete flag is false, route to the Login screen if the flag is true and no valid Session exists, or route to the Dashboard screen if the flag is true and a valid Session exists.
7. WHILE the Splash screen is visible, THE Splash_Controller SHALL display the brand mark animation for a duration in the inclusive range of 1.0 to 2.0 seconds before handing off to the next screen.
8. WHEN the Onboarding screens render text, THE Bilingual_System SHALL render every visible string in the active locale.
9. WHEN the user taps the Skip control on any of the three introduction slides, THE Onboarding_Controller SHALL set the onboarding-complete flag to true AND route to the Login screen.
10. WHEN the user taps the Next control on the first or second introduction slide, THE Onboarding_Controller SHALL advance to the subsequent slide within one frame.
11. WHEN the user taps the Back control on the second or third introduction slide, THE Onboarding_Controller SHALL return to the previous slide within one frame.

---

### Requirement 3: Profile & Role-Adaptive UI (MOD-03)

**User Story:** As an authenticated user, I want my profile screen and editable fields to match my role, so that I only see and modify capabilities relevant to my role.

#### Acceptance Criteria

1. THE Role_Policy SHALL return true for `RolePolicy(role).can(capability)` if and only if the static capability matrix contains role in the allowed set for capability, for every role in {Owner, Freelancer, Both, Manager} and every defined capability.
2. WHEN a user successfully changes role via Change Role, THE Role_Policy SHALL reflect the new role on the next read AND every subscribed screen SHALL rebuild with the updated capabilities within one frame.
3. WHEN User_Repository updateProfile completes successfully, THE current-user observer SHALL emit the updated user value within one frame.
4. WHERE the current user's role is in {Owner, Both}, THE Profile screen SHALL display the Studio Branding section containing logo, signature, VAT BIN, and studio address fields; WHERE the current user's role is in {Freelancer, Manager}, THE Profile screen SHALL hide that section.
5. WHERE the current user's role is in {Freelancer, Both}, THE Profile screen SHALL display the Gear Inventory section sourced from the gear-list observer AND the Companies-I-work-with section sourced from the current-user observer.
6. WHEN a user submits the Add Gear dialog with a gear name whose trimmed length is between 1 and 80 characters inclusive, THE User_Repository SHALL persist the gear item locally AND the gear-list observer SHALL emit the updated list within one frame.
7. WHEN a user removes a gear item, THE User_Repository SHALL delete the item locally AND enqueue the deletion in the Outbox_Queue for remote sync.
8. WHEN the Profile screen renders, THE Clicker_Pro_Client SHALL render from the current-user observer the user's name, role label, avatar initials derived from the user's name, and contact fields {phone, whatsapp, email, address, bio} AND SHALL render lifetime stats {total events, total revenue, total clients} read from the User_Repository AND the User_Repository SHALL trigger a background refresh of lifetime stats from the remote source on Profile open; THE Profile screen SHALL NOT support avatar image upload in this slice.
9. WHEN a user invokes Change Role and confirms in the confirmation dialog, THE Auth_Service SHALL submit the new role to the backend AND on success THE Role_Policy SHALL invalidate cached capabilities.
10. IF a user invokes Change Role and cancels the confirmation dialog, THEN THE current role SHALL remain unchanged AND no network request SHALL be issued.
11. WHEN an Owner or Both user opens the Generate Invite dialog and confirms, THE Auth_Service SHALL request a fresh invite code from the backend AND THE dialog SHALL display the returned six-digit code AND its expiry time.
12. WHEN a user invokes the Edit control on the Profile screen, THE Profile screen SHALL transition to edit-mode AND expose Save and Cancel controls AND render editable fields as input controls bound to a local draft copy of the current user.
13. WHEN a user invokes Save in edit-mode AND all field validators pass, THE User_Repository SHALL persist the draft profile AND THE Profile screen SHALL transition back to view-mode within one frame; IF any field validator fails, THEN THE Profile screen SHALL remain in edit-mode AND display the validation error inline AND no network request SHALL be issued.
14. WHEN a user invokes Cancel in edit-mode, THE Profile screen SHALL discard the draft AND transition back to view-mode within one frame AND no network request SHALL be issued.

---

### Requirement 4: Settings, Distribution & Notification Preferences (MOD-03)

**User Story:** As an authenticated user, I want to control language, notifications, distribution toggle, Bengali numerals, and account actions in one settings surface, so that the app behavior matches my preferences.

#### Acceptance Criteria

1. WHEN a user toggles language on the Settings screen to a value in {en, bn}, THE Preferences_Repository SHALL persist the choice within one frame AND THE Bilingual_System SHALL update the active Locale within one frame.
2. WHEN a user changes any notification preference in {eventReminders, paymentDue, teamMessages, announcements, marketing}, THE Preferences_Repository SHALL persist the change locally within one frame AND enqueue it in the Outbox_Queue for remote sync.
3. WHERE the current user's role is in {Owner, Both}, THE Settings screen SHALL display the Distribution toggle AND the VAT toggle.
4. WHERE the current user's role is in {Freelancer, Manager}, THE Settings screen SHALL hide the Distribution toggle AND the VAT toggle.
5. WHEN a user toggles the Distribution preference, THE Preferences_Repository SHALL persist the new boolean value associated with the user's id within one frame.
6. WHEN a user toggles Bengali Numerals, THE Preferences_Repository SHALL persist the boolean value within one frame, AND WHILE the active locale is bn AND Bengali Numerals is true, THE Clicker_Pro_Client SHALL render numeric values using Unicode code points U+09E6 through U+09EF on every screen that renders numeric values.
7. WHEN the Settings screen reads the current role for capability gating, THE Settings screen SHALL read the role from Role_Policy.
8. WHEN a user invokes Logout from the Settings screen, THE Settings screen SHALL display a confirmation dialog AND on confirm THE Session_Controller SHALL perform the logout per Requirement 1.2; IF the user cancels the dialog, THEN no session change SHALL occur AND no network request SHALL be issued.
9. WHEN a user opens the Settings screen, THE Clicker_Pro_Client SHALL render every preference value from the Preferences_Repository, falling back to the documented defaults {language=en, eventReminders=true, paymentDue=true, teamMessages=true, announcements=true, marketing=false, distributionEnabled=false, bengaliNumerals=false} when no value is persisted, AND SHALL NOT define defaults at the screen layer.
10. WHEN a user taps Privacy Policy, Terms of Service, or Help & Support entries in the Settings screen, THE Clicker_Pro_Client SHALL navigate to the corresponding route by name through the central app router.
11. IF Preferences_Repository persistence fails for any toggle change, THEN THE Settings screen SHALL revert the toggle to its prior value within one frame AND surface an error indication AND THE failed change SHALL NOT be enqueued in the Outbox_Queue.

---

### Requirement 5: Dashboard Compliance, Navigation & Help Stub (MOD-04 + MOD-05 + MOD-50)

**User Story:** As an authenticated user, I want the dashboard and navigation to display my real account data and route between sections by name, so that I see accurate context everywhere I land and the navigation supports later deep links.

#### Acceptance Criteria

1. WHEN the Dashboard screen renders, THE Clicker_Pro_Client SHALL render the user's name, role label, and avatar initials derived from the current-user observer; WHEN a user taps the top-bar search action, THE Clicker_Pro_Client SHALL invoke the global search action stub; WHEN a user taps the avatar control, THE Clicker_Pro_Client SHALL navigate to the Profile route by name through the central app router.
2. WHEN the active language changes, THE Dashboard screen SHALL re-render every visible label in the new locale within one frame.
3. THE bottom navigation SHALL expose exactly five destinations in left-to-right order: Home, Booking, a central FAB action, Finance, and Settings AND SHALL render an active-indicator on the currently selected destination.
4. THE drawer SHALL group entries under the section labels Main, Operations, Finance, and Account AND SHALL expose at minimum Profile, Privacy Policy, Terms of Service, Help & Support, and Logout.
5. WHEN a user taps a bottom-navigation destination or a drawer entry, THE Clicker_Pro_Client SHALL push the corresponding route by name through the central app router.
6. WHEN a user taps the central FAB, THE Clicker_Pro_Client SHALL invoke the New Booking action stub.
7. WHEN a user taps Help & Support in the drawer, THE Clicker_Pro_Client SHALL display the Help stub screen containing at least a screen title, a placeholder body message, and a back action that returns via the central app router.
8. THE Dashboard metric tiles {Today Events, Upcoming, Success, Total} SHALL read their values from a typed metrics observer AND SHALL display the loading state while the observer is loading AND SHALL display the error state on failure with a retry control.
9. WHEN connectivity transitions from online to offline, THE Clicker_Pro_Client SHALL display the Offline Banner across screens that read remote data; WHEN connectivity transitions from offline to online, THE Offline Banner SHALL disappear within one frame.
10. THE Dashboard screen SHALL preserve its existing visual layout, color tokens, and typography unchanged in this slice.
11. WHERE the current user's role is Manager, THE Dashboard screen SHALL hide the Today Collection card; WHERE the current user's role is Freelancer, THE Dashboard screen SHALL display the Today Collection card scoped to the user's own bookings AND SHALL render the Invoice quick-action label as "My Earnings".
12. WHEN a user performs the pull-to-refresh gesture on the Dashboard screen, THE Clicker_Pro_Client SHALL trigger a background refresh of the current user via User_Repository AND of the typed metrics observer.
13. WHEN a user taps a day cell in the weekday strip, THE Dashboard screen SHALL select that day cell AND emit the selection through the dashboard day-selection observer within one frame.

---

### Requirement 6: Offline-First & Theme Contract (MOD-06)

**User Story:** As an authenticated user, I want my edits to survive network outages and the app's visual identity to remain consistent, so that I can work without connectivity and trust the look across modules.

#### Acceptance Criteria

1. WHEN User_Repository updateProfile is invoked, THE User_Repository SHALL commit the change to the local store before contacting the network; IF the network call fails due to a network error, a request timeout, or a 5xx response, THEN the local change SHALL remain intact AND the mutation SHALL be enqueued in the Outbox_Queue.
2. WHEN the application starts with no network available AND a cached user exists locally, THE current-user observer SHALL emit the last cached user from the local store.
3. THE Theme_System SHALL expose all design tokens through the existing `app_colors` and `app_theme` contract AND SHALL NOT introduce new color, spacing, or typography tokens in this slice except for one backward-compatibility alias for SignalOrange.
4. WHEN any screen renders an async value, THE screen SHALL render exactly one of the four shared states {Lens loader, Empty state, Error state, content} using the shared state widgets.
5. WHILE connectivity is online AND the Outbox_Queue is non-empty, THE Outbox_Queue SHALL attempt to drain queued mutations against the remote API using exponential backoff with an initial delay of 2 seconds, doubling on each failure, capped at 300 seconds between attempts.
6. WHEN a queued mutation succeeds, THE Outbox_Queue SHALL remove the corresponding OutboxItem AND THE local record SHALL be marked as synchronized; WHEN a remote update for an entity in {User, UserPreferences, NotificationPreferences, GearItem} arrives concurrent with a pending local change for the same entity, THE Outbox_Queue SHALL apply the last-write-wins conflict tier using the most recent updated_at timestamp.
7. WHEN connectivity transitions from offline to online, THE Clicker_Pro_Client SHALL trigger a background refresh of the current user via User_Repository.
8. THE Clicker_Pro_Client SHALL persist exactly three values in `SharedPreferences` in this slice: the bearer token, the active language code, and the onboarding-complete flag; all other state SHALL live in the local Drift store.
9. IF a queued mutation has failed 5 consecutive times, THEN THE Outbox_Queue SHALL stop automatic retry for that OutboxItem AND mark it as requiring manual retry AND surface a sync-error indication to the user.
10. THE top-bar sync status indicator SHALL render exactly one of three observable states {synced, pending, error} reflecting the current state of the Outbox_Queue: synced when the queue is empty AND no items are in error, pending when the queue contains in-progress or queued items, error when any item is in the manual-retry state.
11. WHEN a user invokes Logout, THE Outbox_Queue SHALL preserve all queued items associated with the user account AND SHALL resume drain attempts when the user re-authenticates with the same account on the same device.

---

### Requirement 7: Bilingual System (MOD-48)

**User Story:** As a Bengali- or English-speaking user, I want the app to honor my language choice persistently and translate every UI string, so that I can use the app fluently in my language.

#### Acceptance Criteria

1. WHEN a user sets the active language to bn, THE Preferences_Repository SHALL persist the choice AND THE Bilingual_System SHALL apply Locale `bn` AND the persisted choice SHALL survive an application restart.
2. FOR every translation key present in both `app_en.arb` and `app_bn.arb`, THE legacy AppStrings shim SHALL return the same string as the generated AppLocalizations lookup for the matching language code.
3. WHILE the active locale is bn AND the user has enabled Bengali Numerals, THE Bilingual_System SHALL render numeric values using Bengali digits in the range U+09E6 through U+09EF.
4. WHILE the active locale is bn, THE Clicker_Pro_Client SHALL apply the Noto Sans Bengali typeface to text widgets via the theme fallback chain.
5. THE Bilingual_System SHALL support exactly two locales in this slice: en and bn.
6. IF a translation key is missing in the active locale's ARB file, THEN THE Bilingual_System SHALL fall back to the English value for that key.
7. WHEN the active language changes at runtime, every visible screen SHALL rebuild text labels in the new locale within one frame.
8. WHEN a date or number is formatted for display, THE Bilingual_System SHALL use a locale-aware formatter consistent with the active locale.

---

### Requirement 8: Privacy, Terms & Account Deletion (MOD-49)

**User Story:** As a user, I want to read the privacy policy and terms in-app, record my consent, request a data export, and request account deletion with a 7-day grace period, so that I retain control over my personal data.

#### Acceptance Criteria

1. WHEN a user invokes Request Delete Account AND types the confirmation phrase "DELETE", THE Legal_Repository SHALL submit the deletion request AND the server-returned `deletedAt` SHALL be approximately equal to the current time plus 7 days AND THE Session_Controller SHALL log the user out AND the Clicker_Pro_Client SHALL display a 7-day grace banner on the Login screen.
2. WHEN a user signs in within the 7-day grace window AND invokes Cancel Delete Account, THE Legal_Repository SHALL submit the cancellation AND the server SHALL clear the user's `deletedAt` AND full access SHALL be restored.
3. WHEN a user opens the Privacy Policy screen, THE Legal_Repository SHALL fetch the privacy text for the active locale AND THE screen SHALL render the markdown body.
4. WHEN a user opens the Terms of Service screen, THE Legal_Repository SHALL fetch the terms text for the active locale AND THE screen SHALL render the markdown body.
5. WHEN a user accepts the Privacy and Terms consent during registration, THE Legal_Repository SHALL record the version string and the timestamp of consent against the user's account.
6. WHEN a user invokes Request Data Export, THE Legal_Repository SHALL submit the request AND surface a status indicating the export is in progress, returning a download URL once the export is ready.
7. IF a user attempts to sign in after the 7-day grace window has elapsed AND the account has been purged by the backend, THEN THE Auth_Service SHALL reject the login as if the account does not exist.
8. WHEN the active language changes while a Privacy or Terms screen is visible, THE Legal_Repository SHALL re-fetch the text for the new locale.

---

### Requirement 9: Bug Fixes & Code Hygiene (Design §13)

**User Story:** As a developer maintaining the existing Clicker Pro codebase, I want every defect listed in the design's Bug Fix Specification to be resolved, so that the slice ships against a clean, buildable, lint-clean baseline.

#### Acceptance Criteria

1. WHEN the project is built, THE build SHALL complete with zero compile errors caused by undefined references to `AppColors.signalOrange` in the Register screen.
2. WHEN a user submits the Register form, THE Register screen SHALL invoke the real Auth_Service register flow AND persist the returned bearer token, AND SHALL NOT mutate a local-only StateProvider in place of a real network call.
3. WHEN the Register screen completes its asynchronous submission, THE Register screen SHALL guard the post-await navigation with a `mounted` check before invoking the navigator.
4. THE Register form SHALL contain a password input AND validators for name, email, phone, and password AND SHALL NOT submit while any validator fails.
5. THE production codebase SHALL contain zero direct uses of `print(...)` for diagnostic output AND every diagnostic log SHALL be routed through the central app logger.
6. THE remote API base URL SHALL be configurable per build via a build-time environment variable AND SHALL NOT be hard-coded to `localhost` in shipped code.
7. THE legacy `auth_provider.dart` orphan stub SHALL be removed AND every call site that previously referenced its `authProvider` SHALL read the canonical Session_Controller instead.
8. WHEN the authentication state changes mid-session — including on a 401 from any authenticated endpoint — THE root widget SHALL re-evaluate its route reactively AND route to the Login screen within one frame without requiring an application restart.
9. THE Profile screen SHALL NOT contain any hard-coded passcode comparison AND the join-team dialog SHALL invoke the Team Invite repository to validate any submitted code against the backend.
10. THE Profile screen AND the Settings screen SHALL read user fields (name, email, phone, role, contact details) from the current-user observer AND SHALL NOT keep local `setState` mirrors of those fields.
11. THE Settings screen SHALL read the current user's role from Role_Policy AND SHALL NOT contain a hard-coded role string.

---

### Requirement 10: Backend API Contract Alignment (Design §12)

**User Story:** As a Flutter client developer, I want the client to invoke every backend endpoint in the documented contract with the exact request shape and response handling described in the design, so that backend gaps surface during development and the client is ready the moment a missing endpoint ships.

#### Acceptance Criteria

1. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/login` with body `{ email, password }` AND handle the 200 response containing `{ token, user }` AND surface a structured error on 4xx responses.
2. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/register` with body `{ name, email, phone, password, role }` where role is in {owner, freelancer, both} AND handle the 201 response containing `{ token, user }` AND surface a structured error on 4xx responses.
3. THE Clicker_Pro_Client SHALL invoke `GET /api/profile` with the bearer token AND handle the 200 response containing `{ user }` AND treat a 401 response as a session-invalidation signal.
4. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/otp/request` with body `{ identifier, purpose }` AND handle the 200 response AND surface a structured error on 4xx responses.
5. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/otp/verify` with body `{ identifier, code, purpose }` AND handle the 200 response containing `{ token, user }` AND surface a structured error on 4xx responses.
6. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/forgot` with body `{ email }` AND handle the 200 response AND surface a structured error on 4xx responses.
7. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/reset` with body `{ token, newPassword }` AND handle the 200 response AND surface a structured error on 4xx responses.
8. THE Clicker_Pro_Client SHALL invoke `POST /api/team/invite` with the bearer token of an Owner or Both user AND handle the 201 response containing `{ code, expiresAt }` AND surface a structured error on 4xx responses.
9. THE Clicker_Pro_Client SHALL invoke `POST /api/auth/accept-invite` with body `{ code, name, email, password }` AND handle the 201 response containing `{ token, user }` AND surface a structured error on 4xx responses.
10. THE Clicker_Pro_Client SHALL invoke `PATCH /api/profile` with the partial user payload AND the bearer token AND handle the 200 response containing `{ user }` AND surface a structured error on 4xx responses.
11. THE Clicker_Pro_Client SHALL invoke `POST /api/profile/role` with body `{ newRole }` AND the bearer token AND handle the 200 response containing `{ user }` AND surface a structured error on 4xx responses.
12. THE Clicker_Pro_Client SHALL invoke `POST /api/account/delete-request` with the bearer token AND handle the 200 response containing `{ deletedAt }` AND surface a structured error on 4xx responses.
13. THE Clicker_Pro_Client SHALL invoke `POST /api/account/cancel-delete` with the bearer token AND handle the 200 response containing `{ user }` AND surface a structured error on 4xx responses.
14. THE Clicker_Pro_Client SHALL invoke `GET /api/legal/privacy?lang=<code>` where code is in {en, bn} AND handle the 200 response containing `{ version, body }` AND surface a structured error on 4xx responses.
15. THE Clicker_Pro_Client SHALL invoke `GET /api/legal/terms?lang=<code>` where code is in {en, bn} AND handle the 200 response containing `{ version, body }` AND surface a structured error on 4xx responses.
16. THE Clicker_Pro_Client SHALL invoke `POST /api/legal/consent` with body `{ version }` AND the bearer token AND handle the 200 response AND surface a structured error on 4xx responses.
17. THE Clicker_Pro_Client SHALL invoke `POST /api/account/export` with the bearer token AND handle the 202 response containing `{ downloadUrl }` AND surface a structured error on 4xx responses.
18. IF any of the endpoints listed in Requirements 10.1 through 10.17 returns a 4xx or 5xx response, THEN THE Clicker_Pro_Client SHALL surface a structured ApiException to the caller AND log the failure through the central app logger.
19. WHEN any endpoint listed above is invoked AND the network is unreachable or the request times out, THE Clicker_Pro_Client SHALL surface a network-level error AND THE caller SHALL render the Offline Banner if applicable.

---

## Property → Requirements Traceability (informational)

The Correctness Properties in `design.md` map back to the acceptance criteria above as follows. This table is informational; the canonical reference is the `**Validates: Requirements X.Y**` line under each property in the design document.

| Design Property | Validates Requirement(s) |
|---|---|
| Property 1: Login persists session | 1.1 |
| Property 2: Logout clears all session state | 1.2 |
| Property 3: 401 force-logout | 1.3 |
| Property 4: Manager registration path is exclusive | 1.4 |
| Property 5: RolePolicy matrix soundness | 3.1 |
| Property 6: Role change invalidates capability cache | 3.2 |
| Property 7: Manager cannot change own role | 1.5 |
| Property 8: Profile update is reactive | 3.3 |
| Property 9: Studio branding is Owner/Both only | 3.4 |
| Property 10: Language persistence | 7.1 |
| Property 11: AppStrings shim parity | 7.2 |
| Property 12: Offline-first write durability | 6.1 |
| Property 13: Offline read survival | 6.2 |
| Property 14: Delete request enforces 7-day grace | 8.1 |
| Property 15: Delete cancellation restores access | 8.2 |
