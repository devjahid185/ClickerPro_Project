# Implementation Plan: Foundation MVP

## Overview

This plan converts the Foundation MVP design into incremental, PR-sized Flutter tasks. The first wave unblocks the build by fixing six `signalOrange` compile errors (alias added in `app_colors.dart`). After that, the codebase is reorganized into a feature-first layout, all foundational infrastructure (config, ApiClient, KvStore, AppDatabase, ARB) is brought up bottom-up, and screens are wired layer by layer (auth → profile/settings → dashboard/router → legal → polish → tests). Every task cites the requirements it satisfies. Property-based tests are mandatory for the RolePolicy capability matrix (Property 5) and the AppStrings shim parity (Property 11). The final layer applies MOD-04/05/06 motion polish before verification.

Implementation language is **Dart / Flutter** (already established by the design — Riverpod 2 + Drift + http on the client, Node + Prisma on the backend). Tasks marked `(optional)` may be deferred for a faster MVP.

---

## Tasks

### 1. Fix critical compile errors (unblock build)

- [ ] 1.1 Add `signalOrange` backward-compat alias in `app_colors.dart`
  - Inside the SIGNAL ORANGE block, add `static const Color signalOrange = orange;` (consistent with existing `accent` / `void3` / `error` alias pattern)
  - Run `flutter analyze` and confirm the 6 `register_screen.dart` `AppColors.signalOrange` errors clear (lines 49, 60, 71, 81, 105, 117 in current file)
  - _Requirements: 6.3, 9.1_

- [ ] 1.2 Confirm baseline build is green
  - Run `flutter pub get` and `flutter analyze`; expected output: zero errors (warnings about deprecated APIs are acceptable at this stage)
  - Document any remaining analyzer noise as TODO in a single PR description note (no code change here unless an unrelated error surfaces)
  - _Requirements: 9.1_

---

### 2. Project skeleton & dependencies

- [ ] 2.1 Update `pubspec.yaml` with Foundation deps and `flutter.generate: true`
  - Add `flutter_localizations: { sdk: flutter }`, `intl: ^0.20.2`, `drift: ^2.20.0`, `drift_flutter: ^0.2.0`, `sqlite3_flutter_libs: ^0.5.0`, `path_provider: ^2.1.0`, `path: ^1.9.0`, `connectivity_plus: ^6.0.0`, `flutter_markdown: ^0.7.4`
  - Add `dev_dependencies`: `drift_dev: ^2.20.0`, `build_runner: ^2.4.0`
  - Set `flutter: { generate: true, uses-material-design: true }`
  - Run `flutter pub get`
  - _Requirements: 7.5, 6.8_

- [ ] 2.2 Create `core/`, `features/`, `shared/`, `l10n/` folder skeletons under `lib/`
  - Create empty placeholder folders matching the layout in design §7: `core/{env,network,storage,db/{tables,daos},role,sync,logging,navigation}`, `l10n/`, `shared/{states,widgets}`, `features/{auth,onboarding,profile,settings,dashboard,legal,help}/{data,domain,application,presentation}` (presentation-only for `dashboard` and `help`)
  - Add a placeholder `.gitkeep` or stub `_placeholder.dart` in each folder so the structure commits
  - _Requirements: 6.3_

- [ ] 2.3 Create `lib/app.dart` and refactor `lib/main.dart` to use `ProviderScope`
  - `main.dart`: thin entrypoint that calls `runApp(ProviderScope(child: ClickerProApp()))`
  - `app.dart`: `ClickerProApp` `ConsumerWidget` building `MaterialApp` with theme, locale (placeholder default `en`, full wiring lands in 8.x), `home: const SplashScreen()` placeholder (real router lands in 14.x)
  - DO NOT yet wire ARB or session reactivity here; that happens in tasks 8 and 11
  - _Requirements: 6.3_

---

### 3. Core infrastructure: config, logger, KV store, secure store

- [ ] 3.1 Create `core/env/app_config.dart` (env-driven base URL)
  - `class AppConfig { static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://10.0.2.2:5000'); }`
  - Replace any hard-coded `http://localhost:5000` reference in legacy `services/api_service.dart` with `AppConfig.baseUrl` (will be re-deleted in 5.x but the swap protects intermediate builds)
  - _Requirements: 9.6, 10.1, 10.2, 10.3_

- [ ] 3.2 Create `core/logging/app_logger.dart`
  - Implement `AppLogger.e(tag, error, [stackTrace])`, `AppLogger.w(tag, msg)`, `AppLogger.i(tag, msg)`; each guarded by `kDebugMode` and routed through `debugPrint`
  - Replace the three `print(...)` calls currently in `services/api_service.dart` with `AppLogger.e('api', e)` (the file itself will be deleted in 5.x; this protects intermediate state)
  - _Requirements: 9.5_

- [ ] 3.3 Create `core/storage/kv_store.dart` (typed SharedPreferences wrapper)
  - Methods: `readString(key)`, `writeString(key, val)`, `readBool(key)`, `writeBool(key, val)`, `remove(key)`
  - Strictly limited to three keys at this slice: `auth_token`, `app_lang`, `onboarding_complete` (enforce by `_AllowedKeys` constants used in callsites)
  - Expose `kvStoreProvider` in `core/providers.dart` (created in 6.4)
  - _Requirements: 6.8_

- [ ] 3.4 Create `core/storage/secure_store.dart`
  - Wraps `KvStore` for token reads/writes with method names `readToken()`, `writeToken(t)`, `clearToken()`
  - Add `// TODO Phase 2: migrate to flutter_secure_storage` comment block at top
  - _Requirements: 6.8_

- [ ]* 3.5 Write unit tests for `KvStore` and `SecureStore`
  - Test round-trip read/write/remove for each method, using `SharedPreferences.setMockInitialValues({})`
  - _Requirements: 6.8_

---

### 4. Networking: ApiClient + ApiException

- [ ] 4.1 Create `core/network/api_exception.dart`
  - `class ApiException implements Exception { final int statusCode; final String message; final String? body; }` plus `toString()`
  - _Requirements: 10.18_

- [ ] 4.2 Create `core/network/api_client.dart`
  - Constructor: `ApiClient({required this.baseUrl, SecureStore? secure})`
  - Methods: `get(path, {Map<String,String>? query})`, `post(path, {Map<String,dynamic>? body})`, `patch(path, {required Map<String,dynamic> body})`, `delete(path)`
  - Each request: 15-second timeout, JSON `Content-Type`, automatic `Authorization: Bearer <token>` injection from `SecureStore` when token present, central response handler `_handle()` that returns parsed JSON Map for 2xx and throws `ApiException` for 4xx/5xx, logs failures via `AppLogger`
  - On 401 response, emit a sentinel `ApiException(statusCode: 401)` for upstream session-invalidation handling
  - _Requirements: 1.17, 9.5, 10.18, 10.19_

- [ ]* 4.3 Write unit tests for `ApiClient` happy and 4xx paths
  - Use `package:http/testing.dart` `MockClient`; verify auth header injection, JSON encoding, 200 returns parsed map, 401 throws `ApiException` with `statusCode == 401`, 500 throws with logged error
  - _Requirements: 10.18, 10.19_

---

### 5. Local DB (Drift) — tables, DAOs, codegen

- [ ] 5.1 Create Drift tables under `core/db/tables/`
  - `users_table.dart`, `user_preferences_table.dart`, `notification_preferences_table.dart`, `gear_items_table.dart`, `team_invites_table.dart`, `outbox_table.dart` exactly per design §9 (including `pending`, `deletedAt`, `updatedAt` columns)
  - _Requirements: 6.1, 6.2, 6.6, 6.8_

- [ ] 5.2 Create `core/db/app_database.dart` with `@DriftDatabase` annotation listing all 6 tables
  - `schemaVersion: 1`; LazyDatabase-based `_openConnection()` using `path_provider` to write under app documents dir
  - Run `dart run build_runner build --delete-conflicting-outputs` and commit the generated `app_database.g.dart`
  - _Requirements: 6.1, 6.2, 6.8_

- [ ] 5.3 Create one DAO per repository under `core/db/daos/`
  - `users_dao.dart` (`watchCurrent`, `upsertUser`, `clearAll`, `markPending`)
  - `preferences_dao.dart` (`watchByUserId`, `upsertPrefs`, `upsertNotifPrefs`)
  - `gear_dao.dart` (`watchByUserId`, `insertGear`, `deleteGear`)
  - `outbox_dao.dart` (`enqueue`, `watchPending`, `markAttempt`, `delete`)
  - Re-run `build_runner build` if any `@DriftAccessor` classes are added
  - _Requirements: 3.6, 3.7, 4.2, 4.5, 4.6, 6.1, 6.5, 6.6, 6.9_

- [ ]* 5.4 Write unit tests for each DAO using in-memory Drift
  - Use `NativeDatabase.memory()` with `drift_flutter`; test insert + watch emits + update + delete cycles
  - _Requirements: 6.1, 6.2_

---

### 6. Domain models + Riverpod providers root

- [ ] 6.1 Create domain models under `features/auth/domain/`
  - `session.dart`: `Session { token, user, issuedAt; isManager }`
  - `user_role.dart`: `enum UserRole { owner, freelancer, both, manager }` plus `fromString` and `name`
  - `otp_purpose.dart`: `enum OtpPurpose { signup, login, forgotPassword }`
  - _Requirements: 1.1, 1.4, 1.5, 1.6, 1.7, 1.8_

- [ ] 6.2 Create or move `UserModel` domain class under `features/profile/domain/user_model.dart`
  - Fields per design §6 data model; `fromJson` / `toJson` / `copyWith`; derive `studioLabel` and `avatarInitials` getters
  - Keep the existing legacy `models/user_model.dart` until callsites migrate; then delete in task 18
  - _Requirements: 3.8, 5.1, 9.10_

- [ ] 6.3 Create `core/role/capability.dart` and `core/role/role_policy.dart`
  - Capability enum with all 10 values per design §11
  - `RolePolicy { final UserRole role; bool can(Capability c) }` with the static `_matrix` exactly as in design §11
  - _Requirements: 1.5, 1.15, 3.1, 3.4, 3.5, 4.3, 4.4, 4.7, 9.11_

- [ ] 6.4 Create `core/providers.dart` aggregating root providers
  - `apiClientProvider`, `secureStoreProvider`, `kvStoreProvider`, `appDatabaseProvider`
  - `connectivityProvider` (StreamProvider<bool> backed by `connectivity_plus`)
  - Keep repository providers in their respective feature files (added in task 7); re-export from `core/providers.dart` for convenience
  - _Requirements: 5.9, 6.7, 6.10_

- [ ]* 6.5 Property test for `RolePolicy` capability matrix (Property 5)
  - Use `glados` or hand-rolled `Generator` over the cartesian product of `UserRole × Capability`
  - **Property 5: RolePolicy matrix soundness** — `RolePolicy(r).can(c)` is true iff the static matrix contains `r` for `c`, exhaustively for every (role, capability) pair
  - **Validates: Requirements 3.1, 3.4, 3.5, 4.3, 4.4, 9.11**

- [ ]* 6.6 Property test: Manager cannot change own role (Property 7) and Studio branding is Owner/Both only (Property 9)
  - **Property 7:** `RolePolicy(UserRole.manager).can(Capability.changeRole) == false`
  - **Property 9:** `Owner.can(editStudioBranding) == true && Both.can(editStudioBranding) == true && Freelancer.can(editStudioBranding) == false && Manager.can(editStudioBranding) == false`
  - **Validates: Requirements 1.5, 3.4**

---

### 7. Repository contracts and implementations

- [ ] 7.1 Define repository interfaces (domain layer)
  - `features/auth/domain/auth_repository.dart`, `features/auth/domain/team_invite_repository.dart`, `features/profile/domain/user_repository.dart`, `features/settings/domain/preferences_repository.dart`, `features/legal/domain/legal_repository.dart` exactly per design §10
  - _Requirements: 1.1–1.20, 3.3, 3.6, 3.7, 4.1–4.11, 8.1–8.8_

- [ ] 7.2 Implement `AuthApi` in `features/auth/data/auth_api.dart`
  - Methods covering 11 of 17 design §12 endpoints: `login`, `register`, `getProfile`, `requestOtp`, `verifyOtp`, `forgotPassword`, `resetPassword`, `acceptInvite`, `changeRole`, `requestDeleteAccount`, `cancelDeleteAccount`
  - Each method maps response to typed records or domain objects; rethrows `ApiException`
  - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7, 10.9, 10.11, 10.12, 10.13_

- [ ] 7.3 Implement `UserApi` in `features/profile/data/user_api.dart`
  - Methods: `getProfile()` (already in AuthApi too — keep one canonical version here for profile feature), `patchProfile(Map partial)`, `getLifetimeStats()`, `addGear`, `removeGear`
  - _Requirements: 3.8, 10.10_

- [ ] 7.4 Implement `LegalApi` in `features/legal/data/legal_api.dart`
  - Methods: `getPrivacy(String langCode)`, `getTerms(String langCode)`, `recordConsent(String version)`, `requestExport()`
  - _Requirements: 10.14, 10.15, 10.16, 10.17_

- [ ] 7.5 Implement `TeamInviteApi` in `features/auth/data/team_invite_api.dart`
  - Methods: `generateInvite()` returning `{code, expiresAt}`, `peekInvite(String code)` (uses backend validation; if backend lacks endpoint, fall back to validation in `acceptInvite`)
  - _Requirements: 1.14, 1.15, 10.8_

- [ ] 7.6 Implement `AuthRepositoryImpl` in `features/auth/data/auth_repository_impl.dart`
  - Wires `AuthApi`, `UsersDao`, `SecureStore`; on `login`/`register`/`verifyOtp`/`acceptInvite` success: writes token to `SecureStore`, upserts user into Drift, returns `Session`
  - `restoreSession()`: reads token; if present, calls `getProfile` with 10-second timeout; on 200 → return Session, on 401 / network error → clearToken and return null
  - `logout()`: clears token, clears user row in Drift (preserve outbox per Requirement 6.11)
  - `changeRole()`: PATCH-equivalent POST `/api/profile/role`, then upsert user in Drift, returns updated `UserModel`
  - `requestDeleteAccount()` / `cancelDeleteAccount()`: forwards to API, on success updates `users.deletedAt`
  - On any `ApiException(statusCode == 401)` from any authenticated call, emit a one-shot signal (via `Stream<bool>` controller exposed as `forceLogoutStream`) used by SessionController in 8.1 to flip state
  - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.6, 1.10, 1.11, 1.12, 1.16, 1.17, 1.18, 1.19, 8.1, 8.2, 8.7, 9.7, 9.8_

- [ ] 7.7 Implement `UserRepositoryImpl` in `features/profile/data/user_repository_impl.dart`
  - `watchCurrentUser()`: returns `usersDao.watchCurrent()` mapped to `UserModel`
  - `updateProfile(updated)`: writes to Drift FIRST (Property 12 — local-first durability), then PATCH `/api/profile`; on network/5xx failure enqueues OutboxItem and keeps local change; on 2xx clears `pending`
  - `addGear` / `removeGear`: writes to Drift, enqueues outbox
  - `refreshFromRemote()`: GET `/api/profile`, upsert
  - `getLifetimeStats()`: read-through cache
  - _Requirements: 3.3, 3.6, 3.7, 3.8, 6.1, 6.2, 6.6, 6.7, 6.9_

- [ ] 7.8 Implement `PreferencesRepositoryImpl` in `features/settings/data/preferences_repository_impl.dart`
  - Language: stored in `KvStore['app_lang']` (per Requirement 6.8); default `'en'`
  - Notification prefs, distribution, Bengali numerals: stored in Drift `UserPreferencesTable` / `NotificationPreferencesTable`
  - Toggle write path: write Drift → enqueue outbox; on Drift write failure, throw a typed exception so UI can revert (Requirement 4.11)
  - Defaults loaded from a single `_kDefaults` constant per design (no per-screen defaults)
  - _Requirements: 4.1, 4.2, 4.5, 4.6, 4.9, 4.11, 7.1, 7.5_

- [ ] 7.9 Implement `LegalRepositoryImpl` in `features/legal/data/legal_repository_impl.dart`
  - Pass-through to `LegalApi`; in-memory cache by `langCode` for privacy/terms
  - _Requirements: 8.3, 8.4, 8.5, 8.6, 8.8_

- [ ] 7.10 Wire repository providers
  - Add `authApiProvider`, `userApiProvider`, `legalApiProvider`, `teamInviteApiProvider`, `authRepositoryProvider`, `userRepositoryProvider`, `preferencesRepositoryProvider`, `legalRepositoryProvider`, `teamInviteRepositoryProvider` exactly per design §11
  - _Requirements: 1.x–10.x (provider plumbing)_

- [ ]* 7.11 Unit test `AuthRepositoryImpl` with fake `AuthApi` and in-memory Drift
  - Covers login persists token + user, logout clears token + user (preserves outbox), restoreSession 200/401/timeout branches, register rejects role==manager (Property 4)
  - **Property 1: Login persists session** — after login, `secureStore.readToken() != null` and `usersDao.watchCurrent()` emits the user
  - **Property 2: Logout clears session state** — after logout, token null and Drift `users` empty
  - **Property 4: Manager registration path is exclusive** — calling `register(role: manager)` throws an assertion or `ApiException(400)` mock
  - **Validates: Requirements 1.1, 1.2, 1.4, 1.16**

- [ ]* 7.12 Unit test `UserRepositoryImpl.updateProfile` offline durability (Property 12 + 13)
  - Use a fake `UserApi` that throws `SocketException`; assert Drift row reflects the updated value AND `OutboxTable` has a pending entry
  - Restart-simulation test: mount fresh provider scope with no network → `watchCurrentUser` emits cached user
  - **Property 12: Offline-first write durability** — local write survives network failure
  - **Property 13: Offline read survival** — cached user emitted when offline at boot
  - **Validates: Requirements 6.1, 6.2**

---

### 8. Session & Language controllers

- [ ] 8.1 Implement `SessionController` `AsyncNotifier<Session?>` in `features/auth/application/session_controller.dart`
  - `build()` → `authRepository.restoreSession()`
  - `login(email, pwd)`, `register(...)`, `verifyOtp(...)`, `acceptInvite(...)`, `logout()`, `changeRole(newRole)` per design §11
  - Subscribes to `authRepository.forceLogoutStream` and flips state to `AsyncData(null)` on 401 (Requirement 1.3 + 9.8)
  - `changeRole` invalidates `rolePolicyProvider` (Property 6)
  - _Requirements: 1.1, 1.2, 1.3, 1.6, 1.8, 1.11, 1.12, 1.16, 3.2, 3.9, 3.10, 9.7, 9.8_

- [ ] 8.2 Implement `LanguageController` `AsyncNotifier<String>` in `features/settings/application/language_controller.dart`
  - `build()` → `preferencesRepository.getLanguage()` (defaults to `'en'`)
  - `setLanguage(code)` writes through and updates state within one frame
  - Exposes `currentLocale` getter
  - _Requirements: 2.2, 4.1, 7.1, 7.5, 7.7_

- [ ] 8.3 Wire `currentUserProvider`, `gearListProvider`, `rolePolicyProvider` in `features/profile/application/profile_controller.dart`
  - `currentUserProvider`: `StreamProvider<UserModel?>` over `userRepository.watchCurrentUser()`
  - `gearListProvider`: `StreamProvider.family<List<GearItem>, String>`
  - `rolePolicyProvider`: `Provider<RolePolicy>` derived from `currentUserProvider` (defaults to `Owner` while loading to avoid null role flicker)
  - _Requirements: 3.1, 3.2, 3.5, 3.8_

- [ ]* 8.4 Widget test: 401 from any authenticated request routes to Login within one frame (Property 3)
  - Mount `app.dart` with a fake `AuthApi` whose `getProfile` throws `ApiException(401)`; pump and verify route is `LoginScreen`
  - **Property 3: 401 force-logout** — session flips to null within one frame on 401
  - **Validates: Requirements 1.3, 9.8_

- [ ]* 8.5 Widget test: role change rebuilds capability-gated UI within one frame (Property 6 + 8)
  - Pump a probe widget watching `rolePolicyProvider`, call `sessionController.changeRole(UserRole.freelancer)`, verify rebuild reflects new capabilities
  - **Property 6: Role change invalidates capability cache**
  - **Property 8: Profile update is reactive**
  - **Validates: Requirements 3.2, 3.3_

---

### 9. ARB files & bilingual wiring

- [ ] 9.1 Create `l10n.yaml` at project root
  - `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `output-localization-file: app_localizations.dart`, `nullable-getter: false`
  - _Requirements: 7.5_

- [ ] 9.2 Generate `lib/l10n/app_en.arb` and `lib/l10n/app_bn.arb`
  - Port every key from existing `lib/theme/app_strings.dart` `translations` map 1:1 into ARB schema
  - Add metadata blocks (`@key: { description }`) for at least the navigation, auth, and dashboard keys
  - Run `flutter gen-l10n`; commit generated `app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_bn.dart`
  - _Requirements: 7.2, 7.5, 7.6_

- [ ] 9.3 Convert `lib/theme/app_strings.dart` into a `@Deprecated` shim
  - Keep `_legacyMap` (the existing translations) for `BuildContext`-free callers
  - `static String get(String key, String lang) => _legacyMap[lang]?[key] ?? _legacyMap['en']![key] ?? key`
  - Mark class `@Deprecated('Use AppLocalizations.of(context). Removed after Phase 2.')`
  - _Requirements: 7.2, 7.6_

- [ ] 9.4 Wire `MaterialApp` in `app.dart` to use ARB + active locale
  - `localizationsDelegates: AppLocalizations.localizationsDelegates`, `supportedLocales: AppLocalizations.supportedLocales`
  - `locale:` reads from `languageControllerProvider.maybeWhen(data: (c) => Locale(c), orElse: () => const Locale('en'))`
  - Add `Localizations.localeOf(context).languageCode == 'bn'` Noto Sans Bengali fallback in `app_theme.dart` `textTheme` chain (one helper `_bnAware(TextStyle, BuildContext)`)
  - _Requirements: 4.1, 7.1, 7.4, 7.5, 7.7_

- [ ] 9.5 Implement `formatNumber(num, {required lang, required bnNumerals})` in `core/format/number_format.dart`
  - Uses `intl` `NumberFormat.decimalPattern(lang)`; when `lang == 'bn' && bnNumerals == true`, replace each `\d` with `String.fromCharCode(0x09E6 + int)`
  - Add `formatDate(DateTime, {required lang})` using `DateFormat.yMMMd(lang)`
  - _Requirements: 4.6, 7.3, 7.8_

- [ ]* 9.6 Property test: AppStrings shim parity with AppLocalizations (Property 11)
  - Use `glados` or hand-rolled generator over the set of all keys in `app_en.arb`
  - For each `key` and each `lang` in {`en`, `bn`}: assert `AppStrings.get(key, lang) == _appLocalizationsLookup(key, lang)` (build a tiny reflection helper or compare against the same `_legacyMap`)
  - **Property 11: AppStrings shim parity** — every legacy lookup returns the same string as the generated lookup for the matching language
  - **Validates: Requirements 7.2_

- [ ]* 9.7 Unit test `formatNumber` Bengali numeral substitution
  - For `(1234, lang: 'bn', bnNumerals: true)` expect `'১,২৩৪'` (or locale-appropriate separator); for `(1234, lang: 'en', bnNumerals: true)` expect `'1,234'`
  - _Requirements: 4.6, 7.3, 7.8_

---

### 10. Shared state widgets (LensLoader / EmptyState / ErrorState / OfflineBanner)

- [ ] 10.1 Implement `shared/states/lens_loader.dart`
  - Centered orange `CircularProgressIndicator` over `AppColors.voidBlack`; respects current theme spacing tokens
  - _Requirements: 5.8, 6.4_

- [ ] 10.2 Implement `shared/states/empty_state.dart`
  - Icon + message + optional CTA button; accepts `IconData icon`, `String message`, `VoidCallback? onAction`, `String? actionLabel`
  - _Requirements: 6.4_

- [ ] 10.3 Implement `shared/states/error_state.dart`
  - Red icon + message + retry button; accepts `String message`, `VoidCallback? onRetry`
  - _Requirements: 5.8, 6.4_

- [ ] 10.4 Implement `shared/states/offline_banner.dart`
  - Top-of-screen amber strip; `ConsumerWidget` watching `connectivityProvider`; renders zero-height `SizedBox` when online; animated slide-in/out within one frame on transition
  - _Requirements: 5.9, 6.4_

- [ ]* 10.5 Widget tests for each state widget (golden + interaction)
  - Verify `OfflineBanner` toggles based on `connectivityProvider`; verify `ErrorState` invokes `onRetry` on tap
  - _Requirements: 5.9, 6.4_

---

### 11. Splash, Onboarding, Language Picker

- [ ] 11.1 Implement `OnboardingController` and `onboardingCompleteProvider`
  - `FutureProvider<bool>` reading `kvStore.readBool('onboarding_complete') ?? false`
  - `OnboardingController.markComplete()` writes `true`
  - _Requirements: 2.1, 2.4, 2.5, 2.9_

- [ ] 11.2 Implement `features/onboarding/presentation/splash_screen.dart`
  - 1.0–2.0 second animated brand mark (orange ring scale + lens icon fade), single `AnimationController`
  - On animation complete, route based on `onboardingCompleteProvider` and `sessionControllerProvider`: language picker → login → dashboard per design §4
  - _Requirements: 2.1, 2.6, 2.7_

- [ ] 11.3 Implement `features/onboarding/presentation/language_picker_screen.dart`
  - Two large tap targets: "English" and "বাংলা"; tap calls `languageController.setLanguage(code)` AND persists; Continue button routes to onboarding intro
  - Selected language highlights immediately within one frame
  - _Requirements: 2.2, 2.3, 7.1_

- [ ] 11.4 Implement `features/onboarding/presentation/onboarding_screen.dart` (3 slides)
  - `PageView` with 3 slides, Next / Back / Skip / Done controls; on Done or Skip → `markComplete()` and route to Login
  - Every visible string sourced from `AppLocalizations.of(context)` so locale change re-renders within one frame
  - _Requirements: 2.3, 2.4, 2.8, 2.9, 2.10, 2.11, 7.7_

---

### 12. Auth screens (Login / Register / Forgot / OTP / Accept Invite / Role Change)

- [ ] 12.1 Move `screens/login_screen.dart` → `features/auth/presentation/login_screen.dart` and refactor
  - Keep visual code 1:1; replace any direct service call with `ref.read(sessionControllerProvider.notifier).login(email, pwd)`
  - On success: rely on root router to switch (no manual `Navigator.pushReplacement`)
  - On invalid credentials: show inline error from `AsyncError` state
  - Add a "Forgot Password?" link route; add "I have an invite code" link to Accept Invite
  - Bind 7-day grace banner to a `pendingDeletionBannerProvider` (shown if previous session ended via `requestDeleteAccount`; storage in KvStore under `pending_delete_until`)
  - _Requirements: 1.1, 1.3, 1.19, 8.1, 9.7, 9.8, 10.1_

- [ ] 12.2 Move `screens/register_screen.dart` → `features/auth/presentation/register_screen.dart` and rewrite
  - `ConsumerStatefulWidget` so `mounted` is available
  - Wrap fields in `Form` with `GlobalKey<FormState>`; add `Password_Validator` (length ≥ 8, ≥ 1 letter, ≥ 1 digit) and validators for name (1–80 chars), email (regex), phone (digits, non-empty), confirm-password equality
  - Role picker exposes only `{owner, freelancer, both}` (manager hidden — Requirement 1.4)
  - Replace `AuthService.signUp` call with `await ref.read(sessionControllerProvider.notifier).register(...)`; guard post-await navigation with `if (!mounted) return;`
  - Inline duplicate-email error handling on `ApiException(409)`
  - Confirms previous compile errors stay fixed via `signalOrange` alias from 1.1
  - _Requirements: 1.4, 1.6, 1.18, 9.1, 9.2, 9.3, 9.4, 10.2_

- [ ] 12.3 Implement `features/auth/presentation/forgot_password_screen.dart`
  - Email input + submit; calls `authRepository.forgotPassword(email)`; always shows generic acknowledgement on success (Requirement 1.10)
  - On 4xx → inline error
  - Routes back to Login with optional reset-code prompt
  - _Requirements: 1.10, 1.11, 10.6_

- [ ] 12.4 Implement `features/auth/presentation/otp_screen.dart`
  - Six-digit code field (auto-advance), supports purposes `{signup, login, forgotPassword}`
  - Submit → `verifyOtp`; success routes per purpose (forgot → reset password screen, signup/login → dashboard via session change)
  - Resend control with 30-second cooldown; surfaces rate-limit error on 429 (Requirement 1.20)
  - Surfaces "code expired or invalid" on `ApiException(410)` / `(400)` (Requirement 1.9)
  - _Requirements: 1.7, 1.8, 1.9, 1.20, 10.4, 10.5_

- [ ] 12.5 Implement `features/auth/presentation/reset_password_screen.dart`
  - Token field (or auto-populated from forgot flow), new password + confirm with `Password_Validator`
  - Submit → `authRepository.resetPassword(token, newPassword)`; on success route to Login with success snackbar
  - _Requirements: 1.11, 10.7_

- [ ] 12.6 Implement `features/auth/presentation/manager_invite_screen.dart`
  - Code (6-digit) + name + email + password + confirm fields; all validators
  - Calls `authRepository.acceptInvite(...)`; on `404` show "Invalid or expired code" (Requirement 1.13); on success root router routes to Dashboard
  - _Requirements: 1.12, 1.13, 10.9_

- [ ] 12.7 Implement `features/auth/presentation/role_change_dialog.dart`
  - Confirmation dialog showing list of capabilities lost in the new role; cancel returns no-op (no network call); confirm → `sessionController.changeRole(newRole)` → invalidates `rolePolicyProvider`
  - _Requirements: 3.2, 3.9, 3.10, 10.11_

- [ ]* 12.8 Widget tests for auth flow happy paths and validation
  - Login: invalid → error visible; valid → session populated
  - Register: missing password fails validator; success calls `AuthRepository.register`
  - Forgot: any syntactically valid email → generic ack
  - OTP: bad code → error; correct code → session populated
  - Accept Invite: bad code → "Invalid or expired code"
  - _Requirements: 1.6, 1.9, 1.10, 1.13, 1.18, 1.19, 9.2, 9.3, 9.4_

---

### 13. Profile screen (rewire to real data + edit mode + role-adaptive)

- [ ] 13.1 Move `screens/profile_screen.dart` → `features/profile/presentation/profile_screen.dart` and rewire
  - Replace local `setState` mirrors with `ref.watch(currentUserProvider)`, `ref.watch(gearListProvider(userId))`, `ref.watch(rolePolicyProvider)`
  - Render name, role label, avatar initials (derived from name), contact fields, lifetime stats (from `userRepository.getLifetimeStats()`)
  - On screen open, kick off `userRepository.refreshFromRemote()` and lifetime stats refresh in the background (Requirement 3.8)
  - _Requirements: 3.3, 3.8, 9.10_

- [ ] 13.2 Add Studio Branding section gated by `RolePolicy.can(editStudioBranding)`
  - Logo, signature, VAT BIN, studio address fields shown only for Owner/Both
  - _Requirements: 3.4, 9.11_

- [ ] 13.3 Add Gear Inventory + Companies section gated by `RolePolicy.can(editGearInventory)`
  - Gear list sourced from `gearListProvider`; Companies sourced from `currentUserProvider`
  - Implement `add_gear_dialog.dart`: validates trimmed length 1–80; on submit calls `userRepository.addGear(GearItem)`; remove gear deletes locally and enqueues outbox
  - _Requirements: 3.5, 3.6, 3.7_

- [ ] 13.4 Implement edit-mode (Edit / Save / Cancel)
  - Edit → swap to draft copy + editable controls; Save with all validators passing → `userRepository.updateProfile(draft)` then back to view-mode within one frame; Cancel → discard draft, no network call; per-field inline validation errors block submit
  - _Requirements: 3.12, 3.13, 3.14_

- [ ] 13.5 Add gear (top-right) action and Change Role / Generate Invite controls
  - Gear icon in app bar opens overflow menu with Change Role (gated), Generate Invite (gated `Capability.generateTeamInvite`), Delete Account
  - Generate Invite calls `teamInviteRepository.generateInvite()`, shows resulting 6-digit code + 24-hour expiry in a dialog (Requirement 1.14, 3.11, 10.8)
  - Change Role opens `RoleChangeDialog`; hidden for Manager (Requirement 1.5, 1.15)
  - _Requirements: 1.5, 1.14, 1.15, 3.9, 3.10, 3.11, 9.9, 10.8_

- [ ] 13.6 Replace hard-coded "123456" passcode in legacy join-team dialog
  - Either remove dialog entirely (preferred) or rewire it to call `teamInviteRepository.peekInvite(code)`; assert no client-side passcode comparison remains
  - _Requirements: 9.9_

- [ ]* 13.7 Widget test: Profile role-adaptive rendering + edit-mode round trip
  - Owner → Studio block visible; Freelancer → Gear+Companies visible, Studio hidden
  - Edit → modify name → Save → `currentUserProvider` emits new value within one frame; Cancel → no change, no network call
  - _Requirements: 3.3, 3.4, 3.5, 3.12, 3.13, 3.14_

---

### 14. Settings screen (rewire to real prefs + role-adaptive)

- [ ] 14.1 Move `screens/settings_screen.dart` → `features/settings/presentation/settings_screen.dart` and rewire
  - Replace `_userRole = "Owner"` and any local prefs state with `ref.watch(rolePolicyProvider).role` and `ref.watch(preferencesRepositoryProvider)`-backed providers
  - Read defaults from repository (single source) — no per-screen defaults
  - _Requirements: 4.7, 4.9, 9.10, 9.11_

- [ ] 14.2 Wire language toggle, notification prefs, distribution toggle, VAT toggle, Bengali numerals toggle
  - Language: calls `languageController.setLanguage(code)`; UI reflects within one frame
  - Notification prefs: each toggle persists via `preferencesRepository.setNotificationPrefs(...)` and enqueues outbox; on persistence failure, revert toggle and show `SnackBar` error (Requirement 4.11)
  - Distribution + VAT toggles gated by `RolePolicy.can(toggleDistribution)` / `can(toggleVat)`
  - Bengali numerals toggle persists; rendering effect verified by 9.5 helper consumed across screens
  - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.11, 7.1, 7.3_

- [ ] 14.3 Wire Privacy / Terms / Help & Support / Logout entries to named routes
  - Each entry calls `Navigator.of(context).pushNamed(RouteNames.privacy)` etc.
  - Logout shows confirmation dialog; on confirm `sessionController.logout()`; on cancel no-op (no network call)
  - _Requirements: 4.8, 4.10, 5.4, 5.5, 5.7_

- [ ]* 14.4 Widget test: Settings role-adaptive + persistence revert on failure
  - Freelancer → Distribution + VAT hidden; Owner → both visible
  - Force `setNotificationPrefs` to throw; assert toggle reverts to prior value within one frame and snackbar shown
  - _Requirements: 4.3, 4.4, 4.11_

---

### 15. Dashboard rewire + central App Router

- [ ] 15.1 Implement `core/navigation/route_names.dart` with constants for every route
  - `splash`, `languagePicker`, `onboarding`, `login`, `register`, `forgot`, `otp`, `resetPassword`, `acceptInvite`, `dashboard`, `profile`, `settings`, `privacy`, `terms`, `help`, `dataExport`, `deleteAccount`
  - _Requirements: 5.5_

- [ ] 15.2 Implement `core/navigation/app_router.dart`
  - `MaterialApp.onGenerateRoute` builder mapping every name to a route; auth-guard helper that redirects to `login` if `sessionControllerProvider.value == null` for protected routes
  - Reactive: root widget watches `sessionControllerProvider` and rebuilds on session change so 401 routes back to Login (Requirement 9.8)
  - _Requirements: 5.5, 9.8_

- [ ] 15.3 Move `screens/dashboard_screen.dart` → `features/dashboard/presentation/dashboard_screen.dart` and rewire
  - Header: `ref.watch(currentUserProvider).when(data: ..., loading: LensLoader, error: ErrorState)` for name, role label, avatar initials
  - Search action → invokes global search stub (no-op snackbar for now)
  - Tap avatar → `Navigator.pushNamed(RouteNames.profile)`
  - Replace any direct `LanguageService()` call with `ref.watch(languageControllerProvider)`
  - _Requirements: 5.1, 5.2, 5.10, 9.10_

- [ ] 15.4 Add `dashboardMetricsProvider` (`StreamProvider<DashboardMetrics>`) returning typed metrics
  - Initial impl returns mocked-but-typed values from a single in-memory stream (Phase 2 swaps to real source)
  - Metric tiles use `AsyncValue.when()` to render LensLoader / ErrorState (with retry) / content (Requirement 5.8)
  - _Requirements: 5.8_

- [ ] 15.5 Wire pull-to-refresh and weekday-strip selection
  - Wrap dashboard scroll body in `RefreshIndicator`; `onRefresh` triggers `userRepository.refreshFromRemote()` + `ref.invalidate(dashboardMetricsProvider)`
  - Add `dashboardSelectedDayProvider` (`StateProvider<DateTime>`); weekday strip cells dispatch on tap, selection reflects within one frame
  - _Requirements: 5.12, 5.13_

- [ ] 15.6 Wire bottom navigation (5 destinations) and drawer (4 groups)
  - Bottom nav: Home, Booking, central FAB, Finance, Settings — left-to-right order; active indicator on selected; `onTap` uses `Navigator.pushNamed`
  - Drawer: groups Main / Operations / Finance / Account; entries Profile, Privacy Policy, Terms of Service, Help & Support, Logout (minimum)
  - Central FAB → invokes "New Booking" stub (snackbar)
  - _Requirements: 5.3, 5.4, 5.5, 5.6_

- [ ] 15.7 Apply role-adaptive Today Collection card and Invoice quick-action label
  - Manager: hide Today Collection card
  - Freelancer: scope card to user's own bookings; relabel Invoice quick action → "My Earnings"
  - Owner / Both: full card visible
  - _Requirements: 5.11_

- [ ] 15.8 Wire `OfflineBanner` into `dashboard_screen.dart` (and other remote-data screens)
  - Banner appears within one frame on connectivity loss; on regain, app triggers `userRepository.refreshFromRemote()` (Requirement 6.7)
  - _Requirements: 5.9, 6.4, 6.7_

---

### 16. Legal: Privacy / Terms / Data Export / Delete Account / Help stub

- [ ] 16.1 Implement `features/legal/presentation/privacy_screen.dart`
  - Watches `languageControllerProvider`; calls `legalRepository.getPrivacyText(lang)` via a `privacyBodyProvider(lang)`
  - Renders markdown via `flutter_markdown`; LensLoader / ErrorState as needed
  - On language change while visible → `ref.invalidate(privacyBodyProvider)` to re-fetch (Requirement 8.8)
  - _Requirements: 8.3, 8.8, 10.14_

- [ ] 16.2 Implement `features/legal/presentation/terms_screen.dart`
  - Mirror of Privacy screen but for terms text
  - _Requirements: 8.4, 8.8, 10.15_

- [ ] 16.3 Wire consent recording in Register flow
  - Register screen shows checkbox "I agree to Privacy Policy and Terms of Service"; on submit success call `legalRepository.recordConsent(userId, version, DateTime.now())` (version sourced from privacy/terms response)
  - _Requirements: 8.5, 10.16_

- [ ] 16.4 Implement `features/legal/presentation/data_export_screen.dart`
  - Single button "Request Data Export" → `legalRepository.requestDataExport()`; surfaces "in progress" status; once download URL returns, shows tappable link
  - _Requirements: 8.6, 10.17_

- [ ] 16.5 Implement `features/profile/presentation/delete_account_screen.dart` (7-day grace)
  - Two-step: (1) consequences screen, (2) "Type DELETE to confirm"; submit → `authRepository.requestDeleteAccount()` → returns `deletedAt`
  - On success: persist `pending_delete_until` in `KvStore`, force-logout via `sessionController.logout()`, route to Login
  - Login screen reads `pending_delete_until`; if set, shows banner with "Your account will be deleted on <date>. [Cancel Deletion]" — tap routes to a flow that signs in then calls `authRepository.cancelDeleteAccount()` (Requirement 8.2)
  - _Requirements: 8.1, 8.2, 8.7, 10.12, 10.13_

- [ ] 16.6 Implement `features/help/presentation/help_screen.dart` (stub)
  - Title, placeholder body message ("Help & Support is coming soon"), back action via `Navigator.pop`
  - _Requirements: 5.7_

- [ ]* 16.7 Widget test: Delete request → 7-day grace → cancel restores access (Property 14 + 15)
  - Mock `authRepository.requestDeleteAccount()` to return `now + 7d`; verify logout + login banner; mock `cancelDeleteAccount` and verify restored
  - **Property 14: Delete request enforces 7-day grace** — `deletedAt ≈ now + 7d`
  - **Property 15: Delete cancellation restores access** — `deletedAt` cleared after cancel
  - **Validates: Requirements 8.1, 8.2_

---

### 17. Outbox skeleton + sync status indicator

- [ ] 17.1 Implement `core/sync/outbox_worker.dart` skeleton
  - Watches `connectivityProvider` and `outboxDao.watchPending()`
  - When online and pending exists, attempts to drain with exponential backoff (initial 2s, double each failure, cap 300s)
  - On 5 consecutive failures for an item, marks as `manual_retry` and stops auto-retry for that item (Requirement 6.9)
  - Last-write-wins resolution by comparing `updated_at` for `{User, UserPreferences, NotificationPreferences, GearItem}` entities (Requirement 6.6)
  - On logout, preserves all queued items associated with the user (Requirement 6.11)
  - Note: this is a skeleton — Phase 2 hardens it; tests cover only state transitions
  - _Requirements: 6.5, 6.6, 6.9, 6.11_

- [ ] 17.2 Implement top-bar sync status indicator widget
  - Three states {synced, pending, error}; renders icon + tooltip; placed in dashboard app bar
  - _Requirements: 6.10_

- [ ]* 17.3 Unit test outbox worker state machine
  - Verify exponential backoff schedule (2s, 4s, 8s, …, capped at 300s) and 5-failure manual-retry cutoff
  - _Requirements: 6.5, 6.9_

---

### 18. Cleanup & legacy removal

- [ ] 18.1 Delete `lib/providers/auth_provider.dart` and migrate any straggler call sites
  - Search for `authProvider` references; replace each with `sessionControllerProvider`
  - Run `flutter analyze`; expected: zero broken imports
  - _Requirements: 9.7_

- [ ] 18.2 Delete legacy `lib/services/api_service.dart` (replaced by `core/network/api_client.dart`)
  - Migrate any remaining call sites to `apiClientProvider`
  - _Requirements: 9.5, 9.6_

- [ ] 18.3 Final pass: zero `print(...)` and zero `localhost` literals in `lib/`
  - `grep -r "print(" lib/` and `grep -r "localhost" lib/` should return only string-literal contents inside ARB or test mocks (none in production source)
  - Replace stragglers with `AppLogger.*` and `AppConfig.baseUrl` respectively
  - _Requirements: 9.5, 9.6_

- [ ] 18.4 Delete `lib/screens/`, `lib/widgets/`, `lib/providers/`, `lib/services/`, `lib/models/` after all moves complete
  - Confirm every file has been relocated or deprecated; remove the now-empty top-level legacy folders
  - Run `flutter analyze` — zero errors
  - _Requirements: 6.3, 9.7_

---

### 19. Checkpoint — verify all foundational tests pass

- [ ] 19. Run `flutter pub get && flutter analyze && flutter test`
  - Ensure all unit + widget + property tests written so far pass
  - If any test fails, ask the user before proceeding to polish
  - _Ensure all tests pass, ask the user if questions arise._

---

### 20. Polish & motion (MOD-04 / MOD-05 / MOD-06 motion tokens)

- [ ] 20.1 Page transitions: slide + fade per MOD-05 motion tokens
  - Implement a `LensPageRoute<T>` extending `PageRouteBuilder` with 280ms slide-from-right + cross-fade; register as default in `AppRouter`
  - _Requirements: 6.3, 6.4, 7.7_

- [ ] 20.2 Tap feedback: scale 0.97 + orange-soft 120ms flash per MOD-06
  - Build a `LensTappable` wrapper widget combining `AnimatedScale` (0.97 on press) + `AnimatedContainer` orange-soft tint flash (120ms); apply to primary CTA buttons across auth, profile, settings, dashboard
  - _Requirements: 6.3, 6.4_

- [ ] 20.3 Splash logo: fade + scale per MOD-02
  - Replace placeholder splash animation in 11.2 with the final fade-in (0→1 over 800ms) + scale (0.8→1.0 elastic-out) curves; total duration stays within 1.0–2.0s window
  - _Requirements: 2.7, 6.3_

- [ ] 20.4 Dashboard card stagger entry: fade up 12px with 80ms stagger per MOD-04
  - Wrap dashboard metric tiles + quick-action grid in `_StaggeredFadeUp` builder (each child delayed by `index * 80ms`, translate `Offset(0, 12) → Offset.zero`, opacity 0 → 1, total 320ms per card)
  - _Requirements: 5.10, 6.3_

- [ ] 20.5 Drawer slide: 280ms cubic-bezier per MOD-04
  - Override default `Drawer` opening curve with `Cubic(0.2, 0.0, 0.2, 1.0)` over 280ms
  - _Requirements: 5.4, 6.3_

- [ ] 20.6 Pull-to-refresh: custom orange spinner with rotating "Clicker" wordmark per MOD-04
  - Replace default `RefreshIndicator` indicator builder with a custom widget rendering `AppColors.orange` ring + rotating "Clicker" text mark; rotates while `refreshing == true`
  - _Requirements: 5.12, 6.3_

- [ ] 20.7 Error shake on invalid auth: 3-cycle ±6px per MOD-06
  - On Login / Register / OTP / Accept Invite error, run a `ShakeController` that translates the form `±6px` for 3 cycles (total 360ms) using `Curves.easeInOut`
  - _Requirements: 1.9, 1.13, 1.18, 1.19, 6.3_

- [ ] 20.8 AnimatedSwitcher for metric tile data transitions: cross-fade 180ms per MOD-04
  - Wrap each metric tile value in `AnimatedSwitcher(duration: 180ms)` keyed on the value so data refreshes cross-fade smoothly
  - _Requirements: 5.8, 6.3_

- [ ] 20.9 Hero transitions for avatar (Dashboard → Profile)
  - Wrap dashboard avatar in `Hero(tag: 'user-avatar')` and the profile avatar similarly; ensure the tag is unique per user id
  - _Requirements: 5.1, 6.3_

- [ ] 20.10 (optional) Subtle parallax on Dashboard scroll header
  - Apply a 0.4× scroll-offset translate to the greeting block while scrolling
  - _Requirements: 5.10_

---

### 21. Final verification

- [ ] 21.1 Run `flutter analyze` → expected zero errors, zero new warnings introduced by this slice
  - _Requirements: 9.1, 9.5, 9.6_

- [ ] 21.2 Run `flutter test` → expected all unit, widget, and property tests pass
  - _Requirements: All tested properties_

- [ ] 21.3 Run `flutter build apk --debug` (and `--dart-define=API_BASE_URL=...` smoke build)
  - Verify build succeeds; APK installs and launches to splash → onboarding (first run) or splash → dashboard (returning user with valid token)
  - _Requirements: 1.16, 2.1, 2.5, 2.6, 9.6_

- [ ] 21.4 Final checkpoint — Ensure all tests pass, ask the user if questions arise.

---

## Notes

- Tasks marked with `*` are optional test sub-tasks; they may be skipped for a faster MVP but are strongly recommended (especially the property tests for RolePolicy and AppStrings shim parity).
- Tasks marked with `(optional)` are deferral candidates not on the critical path.
- Each task references specific requirement clauses for traceability — every clause in Requirements 1 through 10 is cited at least once.
- All 11 design §13 bug fixes are addressed: signalOrange alias (1.1), real register network call + token persist (12.2 + 7.6), `mounted` guard (12.2), Form validators + password field (12.2), no print() (3.2 + 18.3), env-driven base URL (3.1 + 18.3), auth_provider.dart deletion (18.1), reactive root on 401 (8.1 + 15.2), no hard-coded passcode (13.6), no setState mirrors of user fields (13.1 + 14.1), no hard-coded role string (14.1).
- All 17 design §12 endpoints are implemented across tasks 7.2–7.5 and surfaced in 12.x / 13.x / 14.x / 16.x screens.
- All 15 design Correctness Properties have a corresponding test task: P1+P2+P4 → 7.11; P3 → 8.4; P5 → 6.5; P6+P8 → 8.5; P7+P9 → 6.6; P10 → covered by 7.8 + 8.2 round-trip semantics validated implicitly (add explicit test if needed); P11 → 9.6; P12+P13 → 7.12; P14+P15 → 16.7.
- Property tests use `glados` or hand-rolled generators per the user's preference; default to `glados` if added as a dev dependency in 2.1 (otherwise hand-roll).
- The Outbox worker is a skeleton in this slice; Phase 2 will harden it. The 5-attempt manual-retry cutoff and 2s→300s exponential backoff are implemented and tested per Requirements 6.5 and 6.9.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2"] },
    { "id": 1, "tasks": ["2.1", "2.2"] },
    { "id": 2, "tasks": ["2.3", "3.1", "3.2", "3.3", "3.4", "3.5", "4.1"] },
    { "id": 3, "tasks": ["4.2", "4.3", "5.1"] },
    { "id": 4, "tasks": ["5.2"] },
    { "id": 5, "tasks": ["5.3", "5.4", "6.1", "6.2", "6.3"] },
    { "id": 6, "tasks": ["6.4", "6.5", "6.6", "7.1"] },
    { "id": 7, "tasks": ["7.2", "7.3", "7.4", "7.5"] },
    { "id": 8, "tasks": ["7.6", "7.7", "7.8", "7.9"] },
    { "id": 9, "tasks": ["7.10", "7.11", "7.12"] },
    { "id": 10, "tasks": ["8.1", "8.2", "8.3"] },
    { "id": 11, "tasks": ["8.4", "8.5", "9.1"] },
    { "id": 12, "tasks": ["9.2", "9.3"] },
    { "id": 13, "tasks": ["9.4", "9.5", "9.6", "9.7"] },
    { "id": 14, "tasks": ["10.1", "10.2", "10.3", "10.4"] },
    { "id": 15, "tasks": ["10.5", "11.1"] },
    { "id": 16, "tasks": ["11.2", "11.3", "11.4"] },
    { "id": 17, "tasks": ["12.1", "12.3", "12.5", "12.6"] },
    { "id": 18, "tasks": ["12.2", "12.4", "12.7"] },
    { "id": 19, "tasks": ["12.8", "13.1"] },
    { "id": 20, "tasks": ["13.2", "13.3", "13.4", "13.5", "13.6"] },
    { "id": 21, "tasks": ["13.7", "14.1"] },
    { "id": 22, "tasks": ["14.2", "14.3"] },
    { "id": 23, "tasks": ["14.4", "15.1"] },
    { "id": 24, "tasks": ["15.2", "15.3"] },
    { "id": 25, "tasks": ["15.4", "15.5", "15.6", "15.7", "15.8"] },
    { "id": 26, "tasks": ["16.1", "16.2", "16.3", "16.4", "16.5", "16.6"] },
    { "id": 27, "tasks": ["16.7", "17.1"] },
    { "id": 28, "tasks": ["17.2", "17.3"] },
    { "id": 29, "tasks": ["18.1", "18.2"] },
    { "id": 30, "tasks": ["18.3"] },
    { "id": 31, "tasks": ["18.4"] },
    { "id": 32, "tasks": ["20.1", "20.2", "20.3", "20.4", "20.5", "20.6", "20.7", "20.8", "20.9", "20.10"] },
    { "id": 33, "tasks": ["21.1"] },
    { "id": 34, "tasks": ["21.2", "21.3"] }
  ]
}
```
