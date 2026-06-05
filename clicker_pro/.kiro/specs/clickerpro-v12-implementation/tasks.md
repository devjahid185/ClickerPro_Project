# Implementation Plan: ClickerPro v12 Phase 1

## Overview

This plan converts the ClickerPro v12 Phase 1 design into incremental, executable tasks that establish the foundational architecture for a professional photography studio management platform. The implementation uses **Dart/Flutter** with offline-first architecture, bilingual support (English/Bengali), and the Deep Ocean dark theme optimized for low-light studio environments.

The plan focuses on:
1. **Theme System**: Deep Ocean dark theme with glass morphism effects
2. **Authentication Foundation**: Mock authentication system for development
3. **Navigation System**: Centralized routing with route guards
4. **Database Foundation**: Drift SQLite with reactive queries
5. **Internationalization**: English/Bengali support with ARB files
6. **Splash Screen**: Branded initialization flow
7. **Login Screen**: Form validation and authentication
8. **Core Infrastructure**: Logging, error handling, connectivity monitoring

Tasks are organized into waves for parallel execution where dependencies allow. Each task references specific requirements for traceability.

## Tasks

- [ ] 1. Set up core infrastructure and environment configuration
  - [ ] 1.1 Verify .env file configuration and AppConfig loader
    - Ensure .env file exists with required variables (API_BASE_URL, ENABLE_ANALYTICS, LOG_LEVEL, ENABLE_CRASHLYTICS)
    - Verify AppConfig singleton in `lib/core/env/app_config.dart` loads configuration on startup
    - Add validation for required environment variables with fallback defaults
    - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.8, 14.9_
  
  - [ ] 1.2 Verify and enhance AppLogger for centralized logging
    - Verify AppLogger in `lib/core/logging/app_logger.dart` exists
    - Ensure log levels are properly implemented (debug, info, warning, error, critical)
    - Implement development vs production log level filtering
    - Add error log persistence to Drift database
    - _Requirements: 9.4, 9.5, 9.6, 9.7, 9.8_
  
  - [ ] 1.3 Set up global error handling and crash recovery
    - Implement unhandled exception catching in main.dart
    - Add user-friendly error dialog for caught exceptions
    - Integrate with AppLogger for exception logging with stack traces
    - Implement crash recovery flow on app restart
    - _Requirements: 9.1, 9.2, 9.3, 9.9, 9.10_

- [ ] 2. Checkpoint - Verify core infrastructure
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 3. Implement Deep Ocean theme system
  - [ ] 3.1 Verify AppColors implementation
    - Verify `lib/theme/app_colors.dart` implements complete Deep Ocean palette
    - Confirm void black surfaces (voidBlack: #020810, voidLight: #0A111A, voidElevated: #141C26)
    - Confirm teal accent colors (teal: #00FFD1, tealLight: #66FFDF, tealSoft, tealGlow)
    - Confirm film white text colors (film: #F5F2EE, filmDim: #B8B5B1, filmMuted: #7A7873)
    - Confirm glass morphism colors (glass: 4% white, glassBorder: 6% white, glassHover: 8% white)
    - Verify backward compatibility aliases (accent → teal, orange → teal)
    - _Requirements: 1.1, 1.2, 1.3, 1.10_
  
  - [ ] 3.2 Verify AppText typography system
    - Verify `lib/theme/app_theme.dart` implements AppText class
    - Confirm Raleway font for brand/display text (brand, metricValue styles)
    - Confirm DM Sans font for body text (body, bodyDim styles)
    - Confirm Space Mono font for monospaced labels (sectionTitle, metricLabel styles)
    - Verify fallback chain: Google Fonts → system default
    - Confirm Bengali support with Noto Sans Bengali font
    - _Requirements: 1.4, 1.5, 1.6, 1.7, 11.1, 11.2, 11.5, 11.6, 11.10_
  
  - [ ] 3.3 Verify AppSpacing and AppRadius scales
    - Verify AppSpacing class with 4px-based scale (xs:4, sm:8, md:12, lg:16, xl:20, xxl:24, xxxl:32)
    - Verify AppRadius class with border radius scale (sm:8, md:10, lg:14, xl:16, pill:999)
    - _Requirements: 1.11, 1.12_
  
  - [ ] 3.4 Verify and enhance AppDecorations
    - Verify AppDecorations class in `lib/theme/app_theme.dart`
    - Ensure glassCard() method with 4% white background and 6% white border
    - Ensure tintedGlassCard() method accepts custom tint colors
    - Ensure iconWrap() method for circular icon containers
    - Ensure pillChip() method for tag/badge display
    - _Requirements: 1.10, 12.1, 12.2, 12.3, 12.4, 12.6, 12.7_
  
  - [ ] 3.5 Verify AppTheme.dark() ThemeData configuration
    - Verify AppTheme.dark() method constructs complete ThemeData
    - Confirm scaffoldBackgroundColor set to AppColors.voidBlack
    - Confirm ColorScheme with teal primary, gold secondary, red error
    - Confirm textTheme uses DM Sans with proper color and sizing
    - Confirm splashColor and highlightColor use tealSoft
    - Verify integration in app.dart MaterialApp
    - _Requirements: 1.1, 1.2, 1.3, 1.8, 1.9_

- [ ] 4. Implement Light Sunset theme support
  - [ ] 4.1 Add Light Sunset color palette to AppColors
    - Add warmCream background color (#FFF8F0)
    - Add warmWhite surface color (#FFFBF5)
    - Add coral primary color (#FF6B6B)
    - Add charcoal text color (#2D3436)
    - _Requirements: 2.1, 2.2, 2.3, 2.4_
  
  - [ ] 4.2 Create AppTheme.light() method
    - Implement light theme ThemeData with Sunset palette
    - Preserve font families and spacing scales from dark theme
    - _Requirements: 2.5_
  
  - [ ] 4.3 Implement theme toggle provider
    - Create ThemeController provider in `lib/features/settings/application/theme_controller.dart`
    - Implement theme state management with Riverpod
    - Add theme preference persistence to Drift database
    - Add theme restoration on app restart
    - _Requirements: 2.6, 2.7, 2.8_
  
  - [ ] 4.4 Add theme toggle UI in settings screen
    - Add theme toggle switch to settings screen
    - Apply reactive theme changes when toggle is pressed
    - _Requirements: 2.6_

- [ ] 5. Checkpoint - Verify theme system
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 6. Implement glass morphism reusable widgets
  - [ ] 6.1 Create GlassCard widget
    - Implement GlassCard in `lib/shared/widgets/glass_card.dart`
    - Apply 4% white background with 6% white border
    - Support custom borderRadius parameter
    - Support custom padding parameter
    - Add tap interaction with ripple effect
    - _Requirements: 12.1, 12.6, 12.7, 12.8_
  
  - [ ] 6.2 Create TintedGlassCard widget
    - Implement TintedGlassCard in `lib/shared/widgets/tinted_glass_card.dart`
    - Accept custom tint color parameter
    - Support custom borderRadius and padding
    - _Requirements: 12.2, 12.6, 12.7_
  
  - [ ] 6.3 Create OfflineBanner widget
    - Implement OfflineBanner in `lib/shared/widgets/offline_banner.dart`
    - Display offline indicator when connectivity is lost
    - Position banner at top of screen
    - Auto-hide when connectivity is restored
    - _Requirements: 13.5, 13.4_
  
  - [ ] 6.4 Export shared widgets from barrel file
    - Create or update `lib/shared/widgets/widgets.dart` barrel file
    - Export GlassCard, TintedGlassCard, OfflineBanner
    - _Requirements: 12.10_

- [ ] 7. Implement database foundation with Drift
  - [ ] 7.1 Verify AppDatabase setup and schema
    - Verify `lib/core/db/app_database.dart` exists with @DriftDatabase annotation
    - Confirm UserPreferences table (id, key, value, updatedAt)
    - Confirm ErrorLogs table (id, level, message, stackTrace, timestamp)
    - Verify schema version and migration strategy
    - Ensure database file path uses application documents directory
    - _Requirements: 6.1, 6.2, 6.4, 6.9_
  
  - [ ] 7.2 Add ThemePreferences table for theme persistence
    - Define ThemePreferences table in `lib/core/db/tables/theme_preferences.dart`
    - Add columns: id (PK), isDarkMode (boolean), updatedAt (datetime)
    - Register table in AppDatabase
    - Generate Drift code with `flutter pub run build_runner build`
    - _Requirements: 2.7, 6.4_
  
  - [ ] 7.3 Add LanguagePreferences table for locale persistence
    - Define LanguagePreferences table in `lib/core/db/tables/language_preferences.dart`
    - Add columns: id (PK), languageCode (text), updatedAt (datetime)
    - Register table in AppDatabase
    - Generate Drift code
    - _Requirements: 8.6, 6.4_
  
  - [ ] 7.4 Add AuthMetadata table for authentication state
    - Define AuthMetadata table in `lib/core/db/tables/auth_metadata.dart`
    - Add columns: id (PK), userId (text), userEmail (text), userRole (text), lastLoginAt (datetime)
    - Register table in AppDatabase
    - Generate Drift code
    - _Requirements: 6.5, 5.6_
  
  - [ ] 7.5 Implement database initialization and error handling
    - Add database initialization in main.dart before app launch
    - Implement clear error messages for database initialization failures
    - Add transaction support for atomic multi-table operations
    - _Requirements: 6.2, 6.9, 6.10_
  
  - [ ]*  7.6 Write unit tests for database operations
    - Test database initialization and schema creation
    - Test table CRUD operations
    - Test transaction rollback on error
    - Test migration strategy
    - _Requirements: 6.2, 6.3, 6.9_

- [ ] 8. Checkpoint - Verify database foundation
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 9. Implement authentication system foundation
  - [ ] 9.1 Create User domain model
    - Implement User model in `lib/features/auth/domain/models/user.dart`
    - Add fields: id, email, name, role (enum: Freelancer, Owner, Both, Manager, WebAdmin)
    - Implement immutable data class with copyWith method
    - _Requirements: 5.6_
  
  - [ ] 9.2 Create Session domain model
    - Implement Session model in `lib/features/auth/domain/models/session.dart`
    - Add fields: user, token, expiresAt
    - Implement immutable data class
    - _Requirements: 5.3_
  
  - [ ] 9.3 Create AuthRepository interface
    - Define AuthRepository interface in `lib/features/auth/domain/auth_repository.dart`
    - Define methods: login(), logout(), getStoredToken(), storeToken(), clearAuth(), isTokenExpired(), getUserFromToken()
    - Define AuthResult return type (user, token, expiresAt)
    - _Requirements: 5.1, 5.3, 5.4, 5.5, 5.8, 5.10_
  
  - [ ] 9.4 Implement MockAuthRepositoryImpl
    - Implement MockAuthRepositoryImpl in `lib/features/auth/data/mock_auth_repository_impl.dart`
    - Implement login() with mock validation (email format, password length >= 8)
    - Simulate 1-second API delay
    - Return mock user with generated token
    - Store token in Flutter Secure Storage via SecureStore
    - Implement token expiration checking
    - _Requirements: 5.10, 5.3, 5.8_
  
  - [ ] 9.5 Create AuthController provider
    - Implement AuthController StateNotifier in `lib/features/auth/application/auth_controller.dart`
    - Define AuthState (isAuthenticated, user, isLoading, error)
    - Implement login(), logout(), and _checkAuthStatus() methods
    - Provide reactive authentication state stream
    - _Requirements: 5.1, 5.7_
  
  - [ ] 9.6 Implement authentication state persistence and restoration
    - Implement state persistence in AuthController when login succeeds
    - Implement state restoration in AuthController constructor via _checkAuthStatus()
    - Store authentication metadata in AuthMetadata table
    - Restore from SecureStore on app restart
    - _Requirements: 5.3, 5.5, 5.8_
  
  - [ ]*  9.7 Write unit tests for authentication system
    - Test MockAuthRepositoryImpl validation logic
    - Test AuthController state transitions
    - Test token storage and retrieval
    - Test authentication state restoration
    - _Requirements: 5.1, 5.3, 5.5, 5.8_

- [ ] 10. Implement navigation system with route guards
  - [ ] 10.1 Verify AppRouter route definitions
    - Verify `lib/core/navigation/app_router.dart` exists
    - Confirm route constants in `lib/core/navigation/route_names.dart` (splash, login, register, dashboard, settings)
    - Verify generateRoute() method handles all routes
    - Add NotFoundScreen for undefined routes
    - _Requirements: 7.1, 7.8_
  
  - [ ] 10.2 Implement route guard logic
    - Implement AuthGuard widget in `lib/core/navigation/auth_guard.dart`
    - Check authentication status via AuthController provider
    - Redirect to login if unauthenticated
    - Allow access if authenticated
    - _Requirements: 7.2, 7.3, 7.4, 7.9_
  
  - [ ] 10.3 Integrate navigation with authentication state
    - Wire AuthGuard to protected routes (dashboard, settings)
    - Implement automatic redirect from login to dashboard when authenticated
    - Add navigation event logging for debugging
    - _Requirements: 7.3, 7.4, 7.9_
  
  - [ ] 10.4 Implement typed route arguments support
    - Add support for passing typed arguments in AppRouter
    - Implement safe argument extraction with type checking
    - _Requirements: 7.6_

- [ ] 11. Checkpoint - Verify navigation and auth integration
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 12. Implement internationalization system
  - [ ] 12.1 Verify ARB files for English and Bengali
    - Verify `lib/l10n/app_en.arb` exists with all required strings
    - Verify `lib/l10n/app_bn.arb` exists with Bengali translations
    - Ensure l10n.yaml configuration is correct
    - Run `flutter gen-l10n` to generate localization classes
    - _Requirements: 8.1, 8.8_
  
  - [ ] 12.2 Create LanguageController provider
    - Implement LanguageController in `lib/features/settings/application/language_controller.dart`
    - Implement locale detection on first launch
    - Set default to Bengali if device locale is bn, otherwise English
    - Provide reactive locale state stream
    - _Requirements: 8.2, 8.3, 8.4_
  
  - [ ] 12.3 Implement language preference persistence
    - Persist selected language to LanguagePreferences table via LanguageController
    - Restore language preference on app restart
    - _Requirements: 8.6, 8.7_
  
  - [ ] 12.4 Add language switcher in settings screen
    - Add language selection UI to settings screen
    - Support English and Bengali options
    - Apply locale change immediately via LanguageController
    - _Requirements: 8.5_
  
  - [ ] 12.5 Implement locale-aware formatting
    - Create formatters in `lib/core/format/` for dates, times, numbers
    - Use Intl package for locale-aware formatting
    - _Requirements: 8.9_
  
  - [ ] 12.6 Add fallback mechanism for missing translations
    - Implement fallback to English when Bengali translation is missing
    - Log missing translation keys for debugging
    - _Requirements: 8.10_

- [ ] 13. Implement splash screen with initialization
  - [ ] 13.1 Create SplashScreen widget
    - Implement SplashScreen in `lib/features/onboarding/presentation/splash_screen.dart`
    - Display ClickerPro logo centered on screen
    - Apply Deep Ocean theme background
    - Add loading indicator below logo
    - _Requirements: 3.1, 3.2, 3.3, 3.4_
  
  - [ ] 13.2 Implement initialization sequence
    - Load .env configuration via AppConfig
    - Initialize AppDatabase connection
    - Initialize Locale system with device default or saved locale
    - Check authentication status via AuthController
    - _Requirements: 3.5, 3.6, 3.7, 3.8_
  
  - [ ] 13.3 Implement navigation routing based on auth state
    - Navigate to Dashboard if user is authenticated
    - Navigate to Login if user is not authenticated
    - Replace splash screen (no back navigation)
    - _Requirements: 3.9, 3.10_
  
  - [ ] 13.4 Add error handling and retry mechanism
    - Display error message if initialization fails
    - Provide retry button
    - Log initialization errors via AppLogger
    - _Requirements: 3.11_
  
  - [ ] 13.5 Optimize initialization time
    - Ensure initialization completes within 3 seconds under normal conditions
    - Run initialization tasks in parallel where possible
    - _Requirements: 3.12_
  
  - [ ]*  13.6 Write widget tests for splash screen
    - Test splash screen displays correctly
    - Test navigation to dashboard when authenticated
    - Test navigation to login when not authenticated
    - Test error handling and retry
    - _Requirements: 3.1, 3.9, 3.10, 3.11_

- [ ] 14. Checkpoint - Verify splash screen flow
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 15. Implement login screen with form validation
  - [ ] 15.1 Create LoginScreen widget
    - Implement LoginScreen in `lib/features/auth/presentation/login_screen.dart`
    - Apply Deep Ocean theme styling
    - Create responsive layout using SafeArea and LayoutBuilder
    - _Requirements: 4.1, 4.2, 4.6, 10.1, 10.2, 10.3, 10.10_
  
  - [ ] 15.2 Implement email and password form fields
    - Add email TextFormField with proper keyboard type
    - Add password TextFormField with secure entry (obscureText: true)
    - Add "Forgot Password" link below password field
    - Add "Register" navigation option at bottom
    - Support bilingual labels via AppLocalizations
    - _Requirements: 4.1, 4.2, 4.4, 4.5, 4.13_
  
  - [ ] 15.3 Implement form validation
    - Validate email format on field blur (onFieldSubmitted or validator)
    - Validate password minimum length (8 characters) on field blur
    - Display validation errors in Bengali/English based on locale
    - Disable login button if validation fails
    - _Requirements: 4.7, 4.8, 4.9, 4.10_
  
  - [ ] 15.4 Implement login button and loading state
    - Add "Login" button with teal accent styling
    - Disable button and show loading indicator during authentication
    - Handle validation errors before calling login
    - _Requirements: 4.3, 4.11, 4.12_
  
  - [ ] 15.5 Wire login screen to AuthController
    - Call AuthController.login() when login button is pressed
    - Watch AuthState for loading and error states
    - Navigate to Dashboard on successful authentication
    - Display error message on authentication failure
    - _Requirements: 4.11, 4.12_
  
  - [ ]*  15.6 Write widget tests for login screen
    - Test form field rendering
    - Test validation error messages
    - Test login button enable/disable
    - Test navigation on successful login
    - Test error display on failed login
    - _Requirements: 4.7, 4.8, 4.9, 4.10, 4.11_

- [ ] 16. Implement connectivity monitoring
  - [ ] 16.1 Create ConnectivityMonitor service
    - Implement ConnectivityMonitor in `lib/core/network/connectivity_monitor.dart`
    - Use connectivity_plus package to monitor network status
    - Provide reactive connectivity status stream
    - Cache connectivity status to avoid excessive checks
    - _Requirements: 13.1, 13.2, 13.6_
  
  - [ ] 16.2 Implement background connectivity checking
    - Poll connectivity status every 10 seconds in background
    - Emit status changes to listening widgets
    - _Requirements: 13.7_
  
  - [ ] 16.3 Integrate OfflineBanner with ConnectivityMonitor
    - Wire OfflineBanner widget to ConnectivityMonitor stream
    - Show banner when device goes offline
    - Hide banner immediately when device comes online
    - _Requirements: 13.3, 13.4_
  
  - [ ] 16.4 Add manual connectivity check trigger
    - Implement manual refresh method in ConnectivityMonitor
    - Expose to UI for user-triggered checks
    - _Requirements: 13.8_
  
  - [ ]*  16.5 Write unit tests for connectivity monitoring
    - Test connectivity status detection
    - Test offline/online status transitions
    - Test background polling
    - Test manual refresh
    - _Requirements: 13.1, 13.2, 13.3, 13.4_

- [ ] 17. Implement responsive layout foundation
  - [ ] 17.1 Define responsive breakpoints
    - Create breakpoint constants in `lib/core/layout/breakpoints.dart`
    - Define mobile (<600px), tablet (600-1024px), desktop (>1024px)
    - _Requirements: 10.2_
  
  - [ ] 17.2 Implement responsive layout utilities
    - Create responsive helper methods using MediaQuery
    - Implement layout selection based on screen width
    - Add support for portrait and landscape orientations
    - _Requirements: 10.3, 10.4, 10.7_
  
  - [ ] 17.3 Apply SafeArea and touch target guidelines
    - Use SafeArea on all screens to respect device notches
    - Ensure minimum touch target size of 48x48px for buttons
    - _Requirements: 10.5, 10.8_
  
  - [ ] 17.4 Implement responsive spacing and font scaling
    - Use MediaQuery to adapt spacing for large screens
    - Scale fonts appropriately for tablet/desktop
    - _Requirements: 10.6_
  
  - [ ] 17.5 Apply responsive layout to LoginScreen and SplashScreen
    - Adapt LoginScreen layout for tablet/desktop
    - Ensure responsive image scaling with BoxFit
    - _Requirements: 10.3, 10.4, 10.9_

- [ ] 18. Checkpoint - Verify responsive layout
  - Ensure all tests pass, ask the user if questions arise.

- [ ] 19. Code quality and architecture validation
  - [ ] 19.1 Verify feature-based folder structure
    - Ensure all features follow presentation/application/domain/data layering
    - Verify separation of concerns (UI, state, business logic, data)
    - _Requirements: 15.1, 15.3_
  
  - [ ] 19.2 Apply Riverpod best practices
    - Verify all providers use proper Riverpod 2.5+ patterns
    - Ensure dependency injection through providers
    - _Requirements: 15.2, 15.3_
  
  - [ ] 19.3 Implement immutable data classes
    - Ensure all domain models are immutable with copyWith methods
    - Use const constructors where possible
    - _Requirements: 15.4, 15.6_
  
  - [ ] 19.4 Run flutter analyze
    - Fix all analyzer errors and warnings
    - Ensure code passes Effective Dart linting rules
    - _Requirements: 15.9, 15.10_
  
  - [ ] 19.5 Verify single responsibility principle
    - Review widget classes for single responsibility
    - Refactor complex widgets into smaller components
    - _Requirements: 15.5_
  
  - [ ] 19.6 Check cyclomatic complexity
    - Identify functions with complexity > 10
    - Refactor complex functions into smaller units
    - _Requirements: 15.7_

- [ ] 20. Final integration and testing
  - [ ] 20.1 Run full application flow test
    - Launch app and verify splash screen initialization
    - Verify navigation to login screen when not authenticated
    - Test login with mock credentials
    - Verify navigation to dashboard on successful login
    - Test logout and return to login screen
    - Test language switching in settings
    - Test theme switching in settings
    - Verify offline banner displays when connectivity is lost
    - _Requirements: All requirements 1-15_
  
  - [ ] 20.2 Run all unit and widget tests
    - Execute `flutter test` and ensure all tests pass
    - Verify test coverage is above 70% for core logic
    - _Requirements: 15.8_
  
  - [ ] 20.3 Test on multiple devices and screen sizes
    - Test on mobile device (320px width)
    - Test on tablet (600-1024px width)
    - Test portrait and landscape orientations
    - _Requirements: 10.1, 10.2, 10.3, 10.7_
  
  - [ ] 20.4 Verify Bengali text rendering
    - Test Bengali translations display correctly
    - Verify Noto Sans Bengali font renders properly
    - Test date/time/number formatting for bn locale
    - _Requirements: 8.1, 8.8, 8.9, 11.2, 11.3_
  
  - [ ] 20.5 Test error handling and recovery
    - Trigger unhandled exception and verify error dialog
    - Test crash recovery on app restart
    - Verify error logs persist to database
    - _Requirements: 9.1, 9.2, 9.3, 9.8, 9.10_

- [ ] 21. Final checkpoint - Production readiness
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional test sub-tasks; they may be skipped for a faster MVP but are strongly recommended for production stability.
- This implementation builds on an existing Flutter codebase with some theme and core infrastructure already in place. Tasks verify existing implementations and enhance them where needed.
- The authentication system uses mock/local implementation for Phase 1; production backend integration will be added in future phases.
- No property-based tests are required for this phase as it focuses on infrastructure and UI foundation rather than complex domain logic.
- All code follows Flutter and Effective Dart best practices with clean architecture principles.
- Each task references specific requirements for traceability and validation.
- The implementation supports offline-first operation with connectivity monitoring and graceful degradation.
- Bilingual support (English/Bengali) is a core requirement tested throughout the implementation.
- The Deep Ocean dark theme is the default; Light Sunset theme is optional but recommended for user preference.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["3.1", "3.2", "3.3", "3.4", "3.5", "7.1"] },
    { "id": 2, "tasks": ["4.1", "4.2", "7.2", "7.3", "7.4", "9.1", "9.2", "9.3", "10.1"] },
    { "id": 3, "tasks": ["4.3", "6.1", "6.2", "7.5", "7.6", "9.4", "9.5", "10.2", "12.1", "16.1", "17.1"] },
    { "id": 4, "tasks": ["4.4", "6.3", "6.4", "9.6", "9.7", "10.3", "10.4", "12.2", "12.5", "16.2", "17.2"] },
    { "id": 5, "tasks": ["12.3", "12.4", "12.6", "16.3", "16.4", "16.5", "17.3", "17.4"] },
    { "id": 6, "tasks": ["13.1", "13.2", "15.1", "15.2", "17.5"] },
    { "id": 7, "tasks": ["13.3", "13.4", "13.5", "13.6", "15.3", "15.4"] },
    { "id": 8, "tasks": ["15.5", "15.6"] },
    { "id": 9, "tasks": ["19.1", "19.2", "19.3", "19.4", "19.5", "19.6"] },
    { "id": 10, "tasks": ["20.1", "20.2", "20.3", "20.4", "20.5"] }
  ]
}
```
