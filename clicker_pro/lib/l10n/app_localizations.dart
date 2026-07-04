import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_bn.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('bn'),
    Locale('en'),
  ];

  /// Login button label and screen title
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email Address'**
  String get email;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @subtitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back to your lens'**
  String get subtitle;

  /// No description provided for @no_account.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get no_account;

  /// No description provided for @create_account.
  ///
  /// In en, this message translates to:
  /// **'Register Now'**
  String get create_account;

  /// Login authentication error message
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password'**
  String get error_auth;

  /// No description provided for @forgot_password.
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgot_password;

  /// No description provided for @show_password.
  ///
  /// In en, this message translates to:
  /// **'Show Password'**
  String get show_password;

  /// No description provided for @hide_password.
  ///
  /// In en, this message translates to:
  /// **'Hide Password'**
  String get hide_password;

  /// No description provided for @coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get coming_soon;

  /// Dashboard quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quick_actions;

  /// No description provided for @today_events.
  ///
  /// In en, this message translates to:
  /// **'Today Events'**
  String get today_events;

  /// No description provided for @success_events.
  ///
  /// In en, this message translates to:
  /// **'Success Events'**
  String get success_events;

  /// No description provided for @total_events.
  ///
  /// In en, this message translates to:
  /// **'Total Events'**
  String get total_events;

  /// No description provided for @btn_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get btn_calendar;

  /// No description provided for @btn_invoice.
  ///
  /// In en, this message translates to:
  /// **'Invoice'**
  String get btn_invoice;

  /// No description provided for @btn_chat.
  ///
  /// In en, this message translates to:
  /// **'Team Chat'**
  String get btn_chat;

  /// No description provided for @btn_team.
  ///
  /// In en, this message translates to:
  /// **'My Team'**
  String get btn_team;

  /// No description provided for @role_label.
  ///
  /// In en, this message translates to:
  /// **'Current Role'**
  String get role_label;

  /// Drawer menu entry — Dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get menu_dashboard;

  /// No description provided for @menu_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get menu_calendar;

  /// No description provided for @menu_bookings.
  ///
  /// In en, this message translates to:
  /// **'All Bookings'**
  String get menu_bookings;

  /// No description provided for @menu_team.
  ///
  /// In en, this message translates to:
  /// **'Team Management'**
  String get menu_team;

  /// No description provided for @account_section.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account_section;

  /// No description provided for @menu_profile.
  ///
  /// In en, this message translates to:
  /// **'My Profile'**
  String get menu_profile;

  /// No description provided for @menu_settings.
  ///
  /// In en, this message translates to:
  /// **'App Settings'**
  String get menu_settings;

  /// No description provided for @menu_logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get menu_logout;

  /// Bottom navigation — Home
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get nav_home;

  /// No description provided for @nav_booking.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get nav_booking;

  /// No description provided for @nav_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get nav_finance;

  /// No description provided for @nav_settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get nav_settings;

  /// No description provided for @pref_lang.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get pref_lang;

  /// No description provided for @pref_dist.
  ///
  /// In en, this message translates to:
  /// **'Distribution'**
  String get pref_dist;

  /// No description provided for @pref_notif.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get pref_notif;

  /// No description provided for @biz_vat.
  ///
  /// In en, this message translates to:
  /// **'VAT (15% NBR)'**
  String get biz_vat;

  /// No description provided for @biz_studio.
  ///
  /// In en, this message translates to:
  /// **'Studio Info'**
  String get biz_studio;

  /// No description provided for @app_about.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get app_about;

  /// No description provided for @app_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get app_help;

  /// No description provided for @app_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get app_privacy;

  /// No description provided for @app_terms.
  ///
  /// In en, this message translates to:
  /// **'Terms of Service'**
  String get app_terms;

  /// No description provided for @prof_specialization.
  ///
  /// In en, this message translates to:
  /// **'Specialization'**
  String get prof_specialization;

  /// No description provided for @prof_gear.
  ///
  /// In en, this message translates to:
  /// **'My Gear Inventory'**
  String get prof_gear;

  /// No description provided for @add_gear.
  ///
  /// In en, this message translates to:
  /// **'Add New Gear'**
  String get add_gear;

  /// No description provided for @edit_profile.
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get edit_profile;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @change_role.
  ///
  /// In en, this message translates to:
  /// **'Change Role'**
  String get change_role;

  /// No description provided for @studio_logo.
  ///
  /// In en, this message translates to:
  /// **'Studio Logo'**
  String get studio_logo;

  /// No description provided for @digital_signature.
  ///
  /// In en, this message translates to:
  /// **'Digital Signature'**
  String get digital_signature;

  /// No description provided for @vat_bin.
  ///
  /// In en, this message translates to:
  /// **'VAT Registration (BIN)'**
  String get vat_bin;

  /// No description provided for @studio_address.
  ///
  /// In en, this message translates to:
  /// **'Studio Address'**
  String get studio_address;

  /// No description provided for @whatsapp.
  ///
  /// In en, this message translates to:
  /// **'WhatsApp Number'**
  String get whatsapp;

  /// No description provided for @bank_details.
  ///
  /// In en, this message translates to:
  /// **'Bank Account Details'**
  String get bank_details;

  /// No description provided for @bio.
  ///
  /// In en, this message translates to:
  /// **'Bio'**
  String get bio;

  /// No description provided for @my_companies.
  ///
  /// In en, this message translates to:
  /// **'My Companies'**
  String get my_companies;

  /// No description provided for @lifetime_stats.
  ///
  /// In en, this message translates to:
  /// **'Lifetime Stats'**
  String get lifetime_stats;

  /// No description provided for @join_team.
  ///
  /// In en, this message translates to:
  /// **'Join a Studio'**
  String get join_team;

  /// No description provided for @enter_passcode.
  ///
  /// In en, this message translates to:
  /// **'Enter 6-Digit Passcode'**
  String get enter_passcode;

  /// No description provided for @invalid_passcode.
  ///
  /// In en, this message translates to:
  /// **'Invalid Passcode. Please try again.'**
  String get invalid_passcode;

  /// No description provided for @joined_success.
  ///
  /// In en, this message translates to:
  /// **'Successfully joined the team!'**
  String get joined_success;

  /// No description provided for @sidebar_main.
  ///
  /// In en, this message translates to:
  /// **'Main'**
  String get sidebar_main;

  /// No description provided for @sidebar_ops.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get sidebar_ops;

  /// No description provided for @sidebar_finance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get sidebar_finance;

  /// No description provided for @sidebar_account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get sidebar_account;

  /// No description provided for @menu_tasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get menu_tasks;

  /// No description provided for @menu_reedit.
  ///
  /// In en, this message translates to:
  /// **'Re-edits'**
  String get menu_reedit;

  /// No description provided for @menu_gear.
  ///
  /// In en, this message translates to:
  /// **'Gear Inventory'**
  String get menu_gear;

  /// No description provided for @menu_rent.
  ///
  /// In en, this message translates to:
  /// **'Rent Tracking'**
  String get menu_rent;

  /// No description provided for @menu_invoices.
  ///
  /// In en, this message translates to:
  /// **'Invoices'**
  String get menu_invoices;

  /// No description provided for @menu_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get menu_payments;

  /// No description provided for @menu_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get menu_expenses;

  /// No description provided for @menu_reports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get menu_reports;

  /// No description provided for @menu_summary.
  ///
  /// In en, this message translates to:
  /// **'Yearly Summary'**
  String get menu_summary;

  /// No description provided for @menu_help.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get menu_help;

  /// No description provided for @menu_privacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy & Terms'**
  String get menu_privacy;

  /// No description provided for @bookings_title.
  ///
  /// In en, this message translates to:
  /// **'Bookings'**
  String get bookings_title;

  /// No description provided for @bookings_empty.
  ///
  /// In en, this message translates to:
  /// **'No bookings yet. Tap \"+\" to create the first one.'**
  String get bookings_empty;

  /// No description provided for @bookings_could_not_load.
  ///
  /// In en, this message translates to:
  /// **'Could not load bookings.'**
  String get bookings_could_not_load;

  /// No description provided for @bookings_new_booking.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get bookings_new_booking;

  /// No description provided for @bookings_new_booking_screen.
  ///
  /// In en, this message translates to:
  /// **'New Booking'**
  String get bookings_new_booking_screen;

  /// No description provided for @bookings_edit_booking_screen.
  ///
  /// In en, this message translates to:
  /// **'Edit Booking'**
  String get bookings_edit_booking_screen;

  /// No description provided for @bookings_save.
  ///
  /// In en, this message translates to:
  /// **'SAVE'**
  String get bookings_save;

  /// No description provided for @bookings_create.
  ///
  /// In en, this message translates to:
  /// **'Create Booking'**
  String get bookings_create;

  /// No description provided for @bookings_save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get bookings_save_changes;

  /// No description provided for @bookings_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get bookings_cancel;

  /// No description provided for @bookings_discard_changes.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get bookings_discard_changes;

  /// No description provided for @bookings_discard_keep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get bookings_discard_keep;

  /// No description provided for @bookings_discard_confirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get bookings_discard_confirm;

  /// No description provided for @bookings_discard_body.
  ///
  /// In en, this message translates to:
  /// **'You have unsaved changes. Discard them and leave?'**
  String get bookings_discard_body;

  /// No description provided for @bookings_pick_date.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get bookings_pick_date;

  /// No description provided for @bookings_field_title.
  ///
  /// In en, this message translates to:
  /// **'Title'**
  String get bookings_field_title;

  /// No description provided for @bookings_field_event_type.
  ///
  /// In en, this message translates to:
  /// **'Event Type'**
  String get bookings_field_event_type;

  /// No description provided for @bookings_field_date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get bookings_field_date;

  /// No description provided for @bookings_field_start.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get bookings_field_start;

  /// No description provided for @bookings_field_end.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get bookings_field_end;

  /// No description provided for @bookings_field_shift.
  ///
  /// In en, this message translates to:
  /// **'Shift'**
  String get bookings_field_shift;

  /// No description provided for @bookings_field_venue.
  ///
  /// In en, this message translates to:
  /// **'Venue'**
  String get bookings_field_venue;

  /// No description provided for @bookings_field_outdoor.
  ///
  /// In en, this message translates to:
  /// **'Outdoor shoot'**
  String get bookings_field_outdoor;

  /// No description provided for @bookings_field_outdoor_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Affects gear / weather planning.'**
  String get bookings_field_outdoor_subtitle;

  /// No description provided for @bookings_field_bride.
  ///
  /// In en, this message translates to:
  /// **'Bride'**
  String get bookings_field_bride;

  /// No description provided for @bookings_field_groom.
  ///
  /// In en, this message translates to:
  /// **'Groom'**
  String get bookings_field_groom;

  /// No description provided for @bookings_field_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get bookings_field_client;

  /// No description provided for @bookings_field_client_pick.
  ///
  /// In en, this message translates to:
  /// **'Pick or create a client'**
  String get bookings_field_client_pick;

  /// No description provided for @bookings_field_package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get bookings_field_package;

  /// No description provided for @bookings_field_package_pick.
  ///
  /// In en, this message translates to:
  /// **'Pick a package or set a custom price'**
  String get bookings_field_package_pick;

  /// No description provided for @bookings_field_custom_price.
  ///
  /// In en, this message translates to:
  /// **'Custom Price'**
  String get bookings_field_custom_price;

  /// No description provided for @bookings_field_coverage.
  ///
  /// In en, this message translates to:
  /// **'Coverage Hours'**
  String get bookings_field_coverage;

  /// No description provided for @bookings_field_extra_rate.
  ///
  /// In en, this message translates to:
  /// **'Extra hour rate'**
  String get bookings_field_extra_rate;

  /// No description provided for @bookings_field_drive.
  ///
  /// In en, this message translates to:
  /// **'Drive link'**
  String get bookings_field_drive;

  /// No description provided for @bookings_field_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bookings_field_notes;

  /// No description provided for @bookings_hide_payment.
  ///
  /// In en, this message translates to:
  /// **'Hide payment from team'**
  String get bookings_hide_payment;

  /// No description provided for @bookings_hide_payment_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Manager and Freelancer roles will not see payment or payout fields for this booking.'**
  String get bookings_hide_payment_subtitle;

  /// No description provided for @bookings_section_client.
  ///
  /// In en, this message translates to:
  /// **'Client'**
  String get bookings_section_client;

  /// No description provided for @bookings_section_schedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get bookings_section_schedule;

  /// No description provided for @bookings_section_package.
  ///
  /// In en, this message translates to:
  /// **'Package'**
  String get bookings_section_package;

  /// No description provided for @bookings_section_payments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get bookings_section_payments;

  /// No description provided for @bookings_section_assignments.
  ///
  /// In en, this message translates to:
  /// **'Assignments'**
  String get bookings_section_assignments;

  /// No description provided for @bookings_section_status_history.
  ///
  /// In en, this message translates to:
  /// **'Status History'**
  String get bookings_section_status_history;

  /// No description provided for @bookings_section_reedits.
  ///
  /// In en, this message translates to:
  /// **'Re-edit requests'**
  String get bookings_section_reedits;

  /// No description provided for @bookings_section_notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get bookings_section_notes;

  /// No description provided for @bookings_assignments_empty.
  ///
  /// In en, this message translates to:
  /// **'No assignments yet. Tap \"+\" above to add one.'**
  String get bookings_assignments_empty;

  /// No description provided for @bookings_no_status_changes.
  ///
  /// In en, this message translates to:
  /// **'No status changes yet.'**
  String get bookings_no_status_changes;

  /// No description provided for @bookings_could_not_load_detail.
  ///
  /// In en, this message translates to:
  /// **'Could not load this booking.'**
  String get bookings_could_not_load_detail;

  /// No description provided for @bookings_calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get bookings_calendar;

  /// No description provided for @bookings_calendar_could_not_load.
  ///
  /// In en, this message translates to:
  /// **'Could not load this month.'**
  String get bookings_calendar_could_not_load;

  /// No description provided for @bookings_prev_month.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get bookings_prev_month;

  /// No description provided for @bookings_next_month.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get bookings_next_month;

  /// No description provided for @sync_synced.
  ///
  /// In en, this message translates to:
  /// **'Synced'**
  String get sync_synced;

  /// No description provided for @sync_pending_tap.
  ///
  /// In en, this message translates to:
  /// **'Sync pending — tap for details'**
  String get sync_pending_tap;

  /// No description provided for @sync_error_tap.
  ///
  /// In en, this message translates to:
  /// **'Sync error — tap to resolve'**
  String get sync_error_tap;

  /// No description provided for @sync_title.
  ///
  /// In en, this message translates to:
  /// **'Sync'**
  String get sync_title;

  /// No description provided for @sync_no_pending.
  ///
  /// In en, this message translates to:
  /// **'No pending changes'**
  String get sync_no_pending;

  /// No description provided for @sync_pending_count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 pending change} other{{count} pending changes}}'**
  String sync_pending_count(int count);

  /// No description provided for @sync_will_sync_when_online.
  ///
  /// In en, this message translates to:
  /// **'Will sync automatically when connectivity returns.'**
  String get sync_will_sync_when_online;

  /// No description provided for @sync_anything_will_sync.
  ///
  /// In en, this message translates to:
  /// **'Anything you save will sync as soon as you go online.'**
  String get sync_anything_will_sync;

  /// No description provided for @sync_retry.
  ///
  /// In en, this message translates to:
  /// **'RETRY'**
  String get sync_retry;

  /// No description provided for @sync_manual_retry_section.
  ///
  /// In en, this message translates to:
  /// **'Manual retry needed'**
  String get sync_manual_retry_section;

  /// No description provided for @sync_everything_synced.
  ///
  /// In en, this message translates to:
  /// **'Everything is synced.'**
  String get sync_everything_synced;

  /// No description provided for @sync_stuck_label.
  ///
  /// In en, this message translates to:
  /// **'STUCK'**
  String get sync_stuck_label;

  /// No description provided for @expenses_title.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get expenses_title;

  /// No description provided for @expenses_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet'**
  String get expenses_empty_title;

  /// No description provided for @expenses_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record your first expense.'**
  String get expenses_empty_subtitle;

  /// No description provided for @expenses_add.
  ///
  /// In en, this message translates to:
  /// **'Record expense'**
  String get expenses_add;

  /// No description provided for @expenses_add_short.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get expenses_add_short;

  /// No description provided for @expenses_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get expenses_amount;

  /// No description provided for @expenses_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get expenses_category;

  /// No description provided for @expenses_note.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get expenses_note;

  /// No description provided for @expenses_note_optional.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get expenses_note_optional;

  /// No description provided for @expenses_incurred_on.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get expenses_incurred_on;

  /// No description provided for @expenses_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get expenses_save;

  /// No description provided for @expenses_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get expenses_cancel;

  /// No description provided for @expenses_validation_amount_required.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount greater than 0'**
  String get expenses_validation_amount_required;

  /// No description provided for @expenses_validation_category_required.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get expenses_validation_category_required;

  /// No description provided for @expenses_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save expense'**
  String get expenses_save_failed;

  /// No description provided for @expenses_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load expenses'**
  String get expenses_load_failed;

  /// No description provided for @expenses_pl_card_title.
  ///
  /// In en, this message translates to:
  /// **'Profit & Loss'**
  String get expenses_pl_card_title;

  /// No description provided for @expenses_pl_income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get expenses_pl_income;

  /// No description provided for @expenses_pl_expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expenses_pl_expense;

  /// No description provided for @expenses_pl_net.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get expenses_pl_net;

  /// No description provided for @expenses_pl_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load profit / loss'**
  String get expenses_pl_load_failed;

  /// No description provided for @expenses_category_travel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get expenses_category_travel;

  /// No description provided for @expenses_category_equipment.
  ///
  /// In en, this message translates to:
  /// **'Equipment'**
  String get expenses_category_equipment;

  /// No description provided for @expenses_category_software.
  ///
  /// In en, this message translates to:
  /// **'Software'**
  String get expenses_category_software;

  /// No description provided for @expenses_category_salary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get expenses_category_salary;

  /// No description provided for @expenses_category_marketing.
  ///
  /// In en, this message translates to:
  /// **'Marketing'**
  String get expenses_category_marketing;

  /// No description provided for @expenses_category_studio.
  ///
  /// In en, this message translates to:
  /// **'Studio'**
  String get expenses_category_studio;

  /// No description provided for @expenses_category_food.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get expenses_category_food;

  /// No description provided for @expenses_category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get expenses_category_other;

  /// No description provided for @reports_title.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get reports_title;

  /// No description provided for @reports_year_label.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get reports_year_label;

  /// No description provided for @reports_year_all_time.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get reports_year_all_time;

  /// No description provided for @reports_summary_section.
  ///
  /// In en, this message translates to:
  /// **'Yearly summary'**
  String get reports_summary_section;

  /// No description provided for @reports_revenue.
  ///
  /// In en, this message translates to:
  /// **'Revenue'**
  String get reports_revenue;

  /// No description provided for @reports_expenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get reports_expenses;

  /// No description provided for @reports_payouts.
  ///
  /// In en, this message translates to:
  /// **'Freelancer payouts'**
  String get reports_payouts;

  /// No description provided for @reports_net_profit.
  ///
  /// In en, this message translates to:
  /// **'Net profit'**
  String get reports_net_profit;

  /// No description provided for @reports_summary_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load yearly summary'**
  String get reports_summary_load_failed;

  /// No description provided for @reports_team_section.
  ///
  /// In en, this message translates to:
  /// **'Team performance'**
  String get reports_team_section;

  /// No description provided for @reports_team_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load team performance'**
  String get reports_team_load_failed;

  /// No description provided for @reports_team_empty.
  ///
  /// In en, this message translates to:
  /// **'No team members yet'**
  String get reports_team_empty;

  /// No description provided for @reports_team_events.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get reports_team_events;

  /// No description provided for @reports_team_earnings.
  ///
  /// In en, this message translates to:
  /// **'Earnings'**
  String get reports_team_earnings;

  /// No description provided for @reports_team_pending_reedits.
  ///
  /// In en, this message translates to:
  /// **'Pending re-edits'**
  String get reports_team_pending_reedits;

  /// No description provided for @reports_team_score.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get reports_team_score;

  /// No description provided for @reports_summary_only_for_year.
  ///
  /// In en, this message translates to:
  /// **'Pick a specific year to view the summary.'**
  String get reports_summary_only_for_year;

  /// No description provided for @notifications_title.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications_title;

  /// No description provided for @notifications_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No notifications'**
  String get notifications_empty_title;

  /// No description provided for @notifications_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notifications_empty_subtitle;

  /// No description provided for @notifications_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications'**
  String get notifications_load_failed;

  /// No description provided for @notifications_unread_badge.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String notifications_unread_badge(int count);

  /// No description provided for @notifications_category_operations.
  ///
  /// In en, this message translates to:
  /// **'Operations'**
  String get notifications_category_operations;

  /// No description provided for @notifications_category_payment.
  ///
  /// In en, this message translates to:
  /// **'Payment'**
  String get notifications_category_payment;

  /// No description provided for @notifications_category_reedit.
  ///
  /// In en, this message translates to:
  /// **'Re-edit'**
  String get notifications_category_reedit;

  /// No description provided for @notifications_category_announcement.
  ///
  /// In en, this message translates to:
  /// **'Announcement'**
  String get notifications_category_announcement;

  /// No description provided for @notifications_category_wish.
  ///
  /// In en, this message translates to:
  /// **'Greeting'**
  String get notifications_category_wish;

  /// No description provided for @notifications_category_other.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get notifications_category_other;

  /// No description provided for @gear_title.
  ///
  /// In en, this message translates to:
  /// **'Gear'**
  String get gear_title;

  /// No description provided for @gear_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No gear yet'**
  String get gear_empty_title;

  /// No description provided for @gear_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add your first item.'**
  String get gear_empty_subtitle;

  /// No description provided for @gear_add.
  ///
  /// In en, this message translates to:
  /// **'Add gear'**
  String get gear_add;

  /// No description provided for @gear_add_short.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get gear_add_short;

  /// No description provided for @gear_name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get gear_name;

  /// No description provided for @gear_brand.
  ///
  /// In en, this message translates to:
  /// **'Brand'**
  String get gear_brand;

  /// No description provided for @gear_category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get gear_category;

  /// No description provided for @gear_condition.
  ///
  /// In en, this message translates to:
  /// **'Condition'**
  String get gear_condition;

  /// No description provided for @gear_value.
  ///
  /// In en, this message translates to:
  /// **'Value'**
  String get gear_value;

  /// No description provided for @gear_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get gear_save;

  /// No description provided for @gear_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get gear_cancel;

  /// No description provided for @gear_validation_name_required.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get gear_validation_name_required;

  /// No description provided for @gear_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save gear'**
  String get gear_save_failed;

  /// No description provided for @gear_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get gear_delete;

  /// No description provided for @gear_delete_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Delete this gear?'**
  String get gear_delete_confirm_title;

  /// No description provided for @gear_delete_confirm_subtitle.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get gear_delete_confirm_subtitle;

  /// No description provided for @gear_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not delete gear'**
  String get gear_delete_failed;

  /// No description provided for @gear_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load gear'**
  String get gear_load_failed;

  /// No description provided for @gear_total_value.
  ///
  /// In en, this message translates to:
  /// **'Total kit value'**
  String get gear_total_value;

  /// No description provided for @gear_category_camera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get gear_category_camera;

  /// No description provided for @gear_category_lens.
  ///
  /// In en, this message translates to:
  /// **'Lens'**
  String get gear_category_lens;

  /// No description provided for @gear_category_flash.
  ///
  /// In en, this message translates to:
  /// **'Flash'**
  String get gear_category_flash;

  /// No description provided for @gear_category_tripod.
  ///
  /// In en, this message translates to:
  /// **'Tripod'**
  String get gear_category_tripod;

  /// No description provided for @gear_category_drone.
  ///
  /// In en, this message translates to:
  /// **'Drone'**
  String get gear_category_drone;

  /// No description provided for @gear_category_audio.
  ///
  /// In en, this message translates to:
  /// **'Audio'**
  String get gear_category_audio;

  /// No description provided for @gear_category_lighting.
  ///
  /// In en, this message translates to:
  /// **'Lighting'**
  String get gear_category_lighting;

  /// No description provided for @gear_category_storage.
  ///
  /// In en, this message translates to:
  /// **'Storage'**
  String get gear_category_storage;

  /// No description provided for @gear_category_other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get gear_category_other;

  /// No description provided for @rent_title.
  ///
  /// In en, this message translates to:
  /// **'Rent'**
  String get rent_title;

  /// No description provided for @rent_empty_title.
  ///
  /// In en, this message translates to:
  /// **'No rent records yet'**
  String get rent_empty_title;

  /// No description provided for @rent_empty_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap + to record gear lent or rented.'**
  String get rent_empty_subtitle;

  /// No description provided for @rent_add.
  ///
  /// In en, this message translates to:
  /// **'Record rental'**
  String get rent_add;

  /// No description provided for @rent_add_short.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get rent_add_short;

  /// No description provided for @rent_direction.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get rent_direction;

  /// No description provided for @rent_direction_out.
  ///
  /// In en, this message translates to:
  /// **'Lent out'**
  String get rent_direction_out;

  /// No description provided for @rent_direction_in.
  ///
  /// In en, this message translates to:
  /// **'Rented in'**
  String get rent_direction_in;

  /// No description provided for @rent_counterparty_name.
  ///
  /// In en, this message translates to:
  /// **'Counterparty name'**
  String get rent_counterparty_name;

  /// No description provided for @rent_counterparty_phone.
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get rent_counterparty_phone;

  /// No description provided for @rent_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get rent_amount;

  /// No description provided for @rent_date.
  ///
  /// In en, this message translates to:
  /// **'Rent date'**
  String get rent_date;

  /// No description provided for @rent_return_by.
  ///
  /// In en, this message translates to:
  /// **'Return by'**
  String get rent_return_by;

  /// No description provided for @rent_save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get rent_save;

  /// No description provided for @rent_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get rent_cancel;

  /// No description provided for @rent_validation_name_required.
  ///
  /// In en, this message translates to:
  /// **'Counterparty name is required'**
  String get rent_validation_name_required;

  /// No description provided for @rent_save_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not save rental'**
  String get rent_save_failed;

  /// No description provided for @rent_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load rental history'**
  String get rent_load_failed;

  /// No description provided for @rent_status_active.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get rent_status_active;

  /// No description provided for @rent_status_returned.
  ///
  /// In en, this message translates to:
  /// **'RETURNED'**
  String get rent_status_returned;

  /// No description provided for @rent_status_overdue.
  ///
  /// In en, this message translates to:
  /// **'OVERDUE'**
  String get rent_status_overdue;

  /// No description provided for @rent_mark_returned.
  ///
  /// In en, this message translates to:
  /// **'Mark returned'**
  String get rent_mark_returned;

  /// No description provided for @rent_active_count.
  ///
  /// In en, this message translates to:
  /// **'{count} open rental'**
  String rent_active_count(int count);

  /// No description provided for @help_title.
  ///
  /// In en, this message translates to:
  /// **'Help & Support'**
  String get help_title;

  /// No description provided for @help_faq_section.
  ///
  /// In en, this message translates to:
  /// **'Frequently asked'**
  String get help_faq_section;

  /// No description provided for @help_faq_empty.
  ///
  /// In en, this message translates to:
  /// **'No FAQs published yet.'**
  String get help_faq_empty;

  /// No description provided for @help_faq_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load FAQs'**
  String get help_faq_load_failed;

  /// No description provided for @help_contact_section.
  ///
  /// In en, this message translates to:
  /// **'Need more help?'**
  String get help_contact_section;

  /// No description provided for @help_contact_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Send us a ticket and we will get back within 24 hours.'**
  String get help_contact_subtitle;

  /// No description provided for @help_contact_email.
  ///
  /// In en, this message translates to:
  /// **'support@clickerpro.app'**
  String get help_contact_email;

  /// No description provided for @help_send_ticket.
  ///
  /// In en, this message translates to:
  /// **'Send a ticket'**
  String get help_send_ticket;

  /// No description provided for @help_ticket_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject'**
  String get help_ticket_subject;

  /// No description provided for @help_ticket_message.
  ///
  /// In en, this message translates to:
  /// **'Describe the issue'**
  String get help_ticket_message;

  /// No description provided for @help_ticket_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get help_ticket_send;

  /// No description provided for @help_ticket_cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get help_ticket_cancel;

  /// No description provided for @help_ticket_validation_subject.
  ///
  /// In en, this message translates to:
  /// **'Subject is required'**
  String get help_ticket_validation_subject;

  /// No description provided for @help_ticket_validation_message.
  ///
  /// In en, this message translates to:
  /// **'Message is required'**
  String get help_ticket_validation_message;

  /// No description provided for @help_ticket_sent.
  ///
  /// In en, this message translates to:
  /// **'Thanks — we will reply soon.'**
  String get help_ticket_sent;

  /// No description provided for @help_ticket_send_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send ticket'**
  String get help_ticket_send_failed;

  /// No description provided for @chat_title.
  ///
  /// In en, this message translates to:
  /// **'Team chat'**
  String get chat_title;

  /// No description provided for @chat_no_group_title.
  ///
  /// In en, this message translates to:
  /// **'No team chat yet'**
  String get chat_no_group_title;

  /// No description provided for @chat_no_group_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Create your studio\'s team chat to start messaging your crew.'**
  String get chat_no_group_subtitle;

  /// No description provided for @chat_create_group.
  ///
  /// In en, this message translates to:
  /// **'Create team chat'**
  String get chat_create_group;

  /// No description provided for @chat_create_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the team chat'**
  String get chat_create_failed;

  /// No description provided for @chat_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load chat'**
  String get chat_load_failed;

  /// No description provided for @chat_thread_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load messages'**
  String get chat_thread_load_failed;

  /// No description provided for @chat_message_hint.
  ///
  /// In en, this message translates to:
  /// **'Write a message'**
  String get chat_message_hint;

  /// No description provided for @chat_send.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get chat_send;

  /// No description provided for @chat_send_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not send the message'**
  String get chat_send_failed;

  /// No description provided for @chat_empty_thread.
  ///
  /// In en, this message translates to:
  /// **'No messages yet — say hello!'**
  String get chat_empty_thread;

  /// No description provided for @team_load_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not load team members'**
  String get team_load_failed;

  /// No description provided for @team_empty.
  ///
  /// In en, this message translates to:
  /// **'No team members yet. Invite your first member.'**
  String get team_empty;

  /// No description provided for @team_invite_member.
  ///
  /// In en, this message translates to:
  /// **'Invite Member'**
  String get team_invite_member;

  /// No description provided for @team_generate_code.
  ///
  /// In en, this message translates to:
  /// **'Generate Invite Code'**
  String get team_generate_code;

  /// No description provided for @team_invite_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Share this 6-digit code with your team member. They can enter it during registration.'**
  String get team_invite_subtitle;

  /// No description provided for @team_invite_expires.
  ///
  /// In en, this message translates to:
  /// **'Expires at'**
  String get team_invite_expires;

  /// No description provided for @team_invite_done.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get team_invite_done;

  /// No description provided for @team_invite_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not generate invite code'**
  String get team_invite_failed;

  /// No description provided for @team_remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get team_remove;

  /// No description provided for @team_remove_confirm_title.
  ///
  /// In en, this message translates to:
  /// **'Remove Member'**
  String get team_remove_confirm_title;

  /// No description provided for @team_remove_confirm_body.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to remove'**
  String get team_remove_confirm_body;

  /// No description provided for @team_remove_failed.
  ///
  /// In en, this message translates to:
  /// **'Could not remove member'**
  String get team_remove_failed;

  /// No description provided for @bookingStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bookingStatusPending;

  /// No description provided for @bookingStatusConfirmed.
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get bookingStatusConfirmed;

  /// No description provided for @bookingStatusInProgress.
  ///
  /// In en, this message translates to:
  /// **'In Progress'**
  String get bookingStatusInProgress;

  /// No description provided for @bookingStatusShotComplete.
  ///
  /// In en, this message translates to:
  /// **'Shot Complete'**
  String get bookingStatusShotComplete;

  /// No description provided for @bookingStatusDelivered.
  ///
  /// In en, this message translates to:
  /// **'Delivered'**
  String get bookingStatusDelivered;

  /// No description provided for @bookingStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get bookingStatusCompleted;

  /// No description provided for @bookingStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get bookingStatusCancelled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['bn', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'bn':
      return AppLocalizationsBn();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
