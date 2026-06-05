# Bugfix Requirements Document

## Introduction

The ClickerPro Flutter app requires streamlined navigation from the splash screen directly to the login screen, bypassing the onboarding flow (language picker and intro screens). Currently, first-time users must complete a multi-step onboarding process before reaching the login screen, creating unnecessary friction. This bugfix will simplify the user flow by removing the onboarding intermediary steps while maintaining the existing Deep Ocean dark theme and app functionality.

## Bug Analysis

### Current Behavior (Defect)

1.1 WHEN the app launches for the first time THEN the system navigates from splash screen to language picker screen, requiring manual language selection and continuation through onboarding intro screens before reaching login

1.2 WHEN the onboarding flag is checked in the splash screen THEN the system introduces a 4-second timeout and additional complexity that delays the navigation to login

1.3 WHEN the user has not completed onboarding THEN the system forces navigation through LanguagePickerScreen and OnboardingIntroScreen before allowing access to LoginScreen

### Expected Behavior (Correct)

2.1 WHEN the app launches (first time or returning user) THEN the system SHALL navigate directly from splash screen to login screen after the 1500ms splash dwell time without checking onboarding status

2.2 WHEN the splash screen completes its animation and dwell time THEN the system SHALL immediately route to LoginScreen using the existing fade transition without any intermediate screens

2.3 WHEN the app performs splash navigation THEN the system SHALL NOT attempt to read onboarding completion status from KvStore, eliminating the timeout and flag check logic

### Unchanged Behavior (Regression Prevention)

3.1 WHEN the splash screen displays its animations THEN the system SHALL CONTINUE TO show the logo fade-in, scale, brand fade, and gold halo pulse animations as currently implemented

3.2 WHEN the splash screen navigates to login THEN the system SHALL CONTINUE TO use the existing 320ms fade transition with the same timing and animation curves

3.3 WHEN the login screen loads THEN the system SHALL CONTINUE TO display the mock login functionality that navigates to dashboard without requiring backend authentication

3.4 WHEN the app theme is rendered THEN the system SHALL CONTINUE TO use the Deep Ocean dark theme with voidBlack (#020810) background, teal (#00FFD1) accent, gold (#FFD166), purple (#A78BFA), coral (#FF6B6B), and mint (#34D399) colors

3.5 WHEN text is displayed in any screen THEN the system SHALL CONTINUE TO use Raleway for brand/display text, DM Sans for body text, Space Mono for mono/labels, and Noto Sans Bengali for Bengali fallback

3.6 WHEN users navigate through auth screens (forgot password, register, manager invite) THEN the system SHALL CONTINUE TO use the slide-from-right page transition with Cubic(0.2, 0.8, 0.2, 1) curve over 280ms

3.7 WHEN the language toggle is used on the login screen THEN the system SHALL CONTINUE TO switch between English and Bengali correctly using the LanguageController
