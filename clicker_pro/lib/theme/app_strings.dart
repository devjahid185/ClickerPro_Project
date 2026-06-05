// lib/theme/app_strings.dart
//
// LEGACY shim — exists so existing screens that call AppStrings.get(key, lang)
// keep working during the ARB migration. New code MUST use:
//
//   AppLocalizations.of(context).<key>
//
// Will be removed after Phase 2.

@Deprecated('Use AppLocalizations.of(context). Removed after Phase 2.')
class AppStrings {
  static String get(String key, String lang) {
    final m = _translations;
    return m[lang]?[key] ?? m['en']![key] ?? key;
  }

  // ---------------------------------------------------------------------------
  // Convenience getters — preserved verbatim from the pre-ARB shim so existing
  // call sites (AppStrings.navHome(lang), AppStrings.menuDashboard(lang), …)
  // continue to compile and resolve to the same strings.
  // ---------------------------------------------------------------------------
  static String comingSoon(String lang) => get('coming_soon', lang);
  static String quickActions(String lang) => get('quick_actions', lang);
  static String todayEvents(String lang) => get('today_events', lang);
  static String successEvents(String lang) => get('success_events', lang);
  static String totalEvents(String lang) => get('total_events', lang);
  static String btnCalendar(String lang) => get('btn_calendar', lang);
  static String btnInvoice(String lang) => get('btn_invoice', lang);
  static String btnChat(String lang) => get('btn_chat', lang);
  static String btnTeam(String lang) => get('btn_team', lang);
  static String roleLabel(String lang) => get('role_label', lang);
  static String menuDashboard(String lang) => get('menu_dashboard', lang);
  static String menuCalendar(String lang) => get('menu_calendar', lang);
  static String menuBookings(String lang) => get('menu_bookings', lang);
  static String menuTeam(String lang) => get('menu_team', lang);
  static String accountSection(String lang) => get('account_section', lang);
  static String menuProfile(String lang) => get('menu_profile', lang);
  static String menuSettings(String lang) => get('menu_settings', lang);
  static String menuLogout(String lang) => get('menu_logout', lang);
  static String navHome(String lang) => get('nav_home', lang);
  static String navBooking(String lang) => get('nav_booking', lang);
  static String navFinance(String lang) => get('nav_finance', lang);
  static String navSettings(String lang) => get('nav_settings', lang);

  // ---------------------------------------------------------------------------
  // Translation map — kept verbatim so the shim parity property holds.
  // Source of truth for new code is the generated AppLocalizations; this map
  // mirrors the same key set 1:1 for legacy callers without a BuildContext.
  // ---------------------------------------------------------------------------
  static const Map<String, Map<String, String>> _translations = {
    'en': {
      'login': 'Login',
      'email': 'Email Address',
      'password': 'Password',
      'subtitle': 'Welcome back to your lens',
      'no_account': 'Don\'t have an account?',
      'create_account': 'Register Now',
      'error_auth': 'Invalid email or password',
      'forgot_password': 'Forgot Password?',
      'show_password': 'Show Password',
      'hide_password': 'Hide Password',
      'coming_soon': 'Coming Soon',
      'quick_actions': 'Quick Actions',
      'today_events': 'Today Events',
      'success_events': 'Success Events',
      'total_events': 'Total Events',
      'btn_calendar': 'Calendar',
      'btn_invoice': 'Invoice',
      'btn_chat': 'Team Chat',
      'btn_team': 'My Team',
      'role_label': 'Current Role',
      'menu_dashboard': 'Dashboard',
      'menu_calendar': 'Calendar',
      'menu_bookings': 'All Bookings',
      'menu_team': 'Team Management',
      'account_section': 'Account',
      'menu_profile': 'My Profile',
      'menu_settings': 'App Settings',
      'menu_logout': 'Logout',
      'nav_home': 'Home',
      'nav_booking': 'Bookings',
      'nav_finance': 'Finance',
      'nav_settings': 'Settings',
      // Profile & Settings
      'pref_lang': 'Language',
      'pref_dist': 'Distribution',
      'pref_notif': 'Notifications',
      'pref_customize_dashboard': 'Customize Dashboard',
      'notif_event_reminders': 'Event reminders',
      'notif_payment_due': 'Payment due',
      'notif_team_messages': 'Team messages',
      'notif_announcements': 'Announcements',
      'notif_marketing': 'Marketing',
      'biz_vat': 'VAT (15% NBR)',
      'biz_studio': 'Company Info',
      'app_about': 'About App',
      'app_help': 'Help & Support',
      'app_privacy': 'Privacy Policy',
      'app_terms': 'Terms of Service',
      'prof_specialization': 'Specialization',
      'prof_gear': 'My Gear Inventory',
      'add_gear': 'Add New Gear',
      'edit_profile': 'Edit Profile',
      'save_changes': 'Save Changes',
      'change_role': 'Change Role',
      'studio_logo': 'Company Logo',
      'digital_signature': 'Digital Signature',
      'vat_bin': 'VAT Registration (BIN)',
      'studio_address': 'Company Address',
      'whatsapp': 'WhatsApp Number',
      'bank_details': 'Bank Account Details',
      'bio': 'Bio',
      'my_companies': 'My Companies',
      'lifetime_stats': 'Lifetime Stats',
      'join_team': 'Join a Company',
      'enter_passcode': 'Enter 6-Digit Passcode',
      'invalid_passcode': 'Invalid Passcode. Please try again.',
      'joined_success': 'Successfully joined the team!',
      // Sidebar Groups
      'sidebar_main': 'Main',
      'sidebar_ops': 'Operations',
      'sidebar_finance': 'Finance',
      'sidebar_account': 'Account',
      'menu_tasks': 'Tasks',
      'menu_reedit': 'Re-edits',
      'menu_gear': 'Gear Inventory',
      'menu_rent': 'Rent Tracking',
      'menu_invoices': 'Invoices',
      'menu_payments': 'Payments',
      'menu_expenses': 'Expenses',
      'menu_reports': 'Reports',
      'menu_summary': 'Yearly Summary',
      'menu_help': 'Help & Support',
      'menu_privacy': 'Privacy & Terms',
    },
    'bn': {
      'login': 'লগইন',
      'email': 'ইমেইল ঠিকানা',
      'password': 'পাসওয়ার্ড',
      'subtitle': 'আপনার লেন্সে স্বাগতম',
      'no_account': 'অ্যাকাউন্ট নেই?',
      'create_account': 'এখনই রেজিস্টার করুন',
      'error_auth': 'ভুল ইমেইল বা পাসওয়ার্ড',
      'forgot_password': 'পাসওয়ার্ড ভুলে গেছেন?',
      'show_password': 'পাসওয়ার্ড দেখান',
      'hide_password': 'পাসওয়ার্ড লুকান',
      'coming_soon': 'শীঘ্রই আসছে',
      'quick_actions': 'কুইক অ্যাকশন',
      'today_events': 'আজকের ইভেন্ট',
      'success_events': 'সফল ইভেন্ট',
      'total_events': 'মোট ইভেন্ট',
      'btn_calendar': 'ক্যালেন্ডার',
      'btn_invoice': 'ইনভয়েস',
      'btn_chat': 'টিম চ্যাট',
      'btn_team': 'আমার টিম',
      'role_label': 'বর্তমান রোল',
      'menu_dashboard': 'ড্যাশবোর্ড',
      'menu_calendar': 'ক্যালেন্ডার',
      'menu_bookings': 'সব বুকিং',
      'menu_team': 'টিম ম্যানেজমেন্ট',
      'account_section': 'অ্যাকাউন্ট',
      'menu_profile': 'আমার প্রোফাইল',
      'menu_settings': 'অ্যাপ সেটিংস',
      'menu_logout': 'লগআউট',
      'nav_home': 'হোম',
      'nav_booking': 'বুকিং',
      'nav_finance': 'ফাইন্যান্স',
      'nav_settings': 'সেটিংস',
      'pref_lang': 'ভাষা',
      'pref_dist': 'ডিস্ট্রিবিউশন',
      'pref_notif': 'নোটিফিকেশন',
      'pref_customize_dashboard': 'ড্যাশবোর্ড কাস্টমাইজ করুন',
      'notif_event_reminders': 'ইভেন্ট রিমাইন্ডার',
      'notif_payment_due': 'পেমেন্ট বাকি',
      'notif_team_messages': 'টিম মেসেজ',
      'notif_announcements': 'ঘোষণা',
      'notif_marketing': 'মার্কেটিং',
      'biz_vat': 'ভ্যাট (১৫% এনবিআর)',
      'biz_studio': 'কোম্পানির তথ্য',
      'app_about': 'অ্যাপ সম্পর্কে',
      'app_help': 'সাহায্য ও সাপোর্ট',
      'app_privacy': 'প্রাইভেসি পলিসি',
      'app_terms': 'শর্তাবলী',
      'prof_specialization': 'পেশাগত দক্ষতা',
      'prof_gear': 'গিয়ার ইনভেন্টরি',
      'add_gear': 'নতুন গিয়ার যোগ করুন',
      'edit_profile': 'প্রোফাইল এডিট করুন',
      'save_changes': 'পরিবর্তন সেভ করুন',
      'change_role': 'রোল পরিবর্তন করুন',
      'studio_logo': 'কোম্পানি লোগো',
      'digital_signature': 'ডিজিটাল সিগনেচার',
      'vat_bin': 'ভ্যাট রেজিস্ট্রেশন (BIN)',
      'studio_address': 'কোম্পানির ঠিকানা',
      'whatsapp': 'হোয়াটসঅ্যাপ নম্বর',
      'bank_details': 'ব্যাংক অ্যাকাউন্ট ডিটেইলস',
      'bio': 'বায়ো',
      'my_companies': 'আমার কোম্পানিগুলো',
      'lifetime_stats': 'লাইফটাইম স্ট্যাটস',
      'join_team': 'স্টুডিওতে যোগ দিন',
      'enter_passcode': '৬-ডিজিটের পাসকোড লিখুন',
      'invalid_passcode': 'ভুল পাসকোড। আবার চেষ্টা করুন।',
      'joined_success': 'সফলভাবে টিমে যোগ দিয়েছেন!',
      // Sidebar Groups
      'sidebar_main': 'মূল',
      'sidebar_ops': 'অপারেশন',
      'sidebar_finance': 'ফাইন্যান্স',
      'sidebar_account': 'অ্যাকাউন্ট',
      'menu_tasks': 'টাস্ক',
      'menu_reedit': 'রি-এডিট',
      'menu_gear': 'গিয়ার ইনভেন্টরি',
      'menu_rent': 'রেন্ট ট্র্যাকিং',
      'menu_invoices': 'ইনভয়েস',
      'menu_payments': 'পেমেন্ট',
      'menu_expenses': 'খরচ',
      'menu_reports': 'রিপোর্ট',
      'menu_summary': 'বার্ষিক সারাংশ',
      'menu_help': 'সাহায্য ও সাপোর্ট',
      'menu_privacy': 'প্রাইভেসি ও শর্তাবলী',
    },
  };
}
