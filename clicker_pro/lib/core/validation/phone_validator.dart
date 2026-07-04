// lib/core/validation/phone_validator.dart
//
// Bangladeshi mobile number validation, shared by every phone input in
// the app. A valid number is exactly 11 digits and starts with 01
// (e.g. 01712345678). Formatting characters (spaces, dashes, +88 country
// code) are stripped before checking so pasted numbers still pass.

class PhoneValidator {
  const PhoneValidator._();

  /// Digits-only form of [raw] with an optional leading 88 country code
  /// removed. `+880 17-1234 5678` → `01712345678`.
  static String normalize(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length == 13 && digits.startsWith('880')) {
      digits = digits.substring(2); // 880XXXXXXXXXX → 0XXXXXXXXXX
    }
    return digits;
  }

  static bool isValid(String raw) {
    final digits = normalize(raw);
    return digits.length == 11 && digits.startsWith('01');
  }

  /// TextFormField validator. When [required] is false an empty value
  /// passes; anything non-empty must be a valid 11-digit number.
  static String? validate(
    String? value, {
    bool required = true,
    String lang = 'en',
  }) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) {
      if (!required) return null;
      return lang == 'bn' ? 'ফোন নম্বর দিন' : 'Phone number is required';
    }
    if (!isValid(raw)) {
      return lang == 'bn'
          ? 'সঠিক ১১ ডিজিটের নম্বর দিন (01XXXXXXXXX)'
          : 'Enter a valid 11-digit number (01XXXXXXXXX)';
    }
    return null;
  }
}
