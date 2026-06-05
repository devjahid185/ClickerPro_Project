// lib/features/auth/domain/otp_purpose.dart

enum OtpPurpose {
  signup,
  login,
  forgotPassword;

  static OtpPurpose fromString(
    String? raw, {
    OtpPurpose fallback = OtpPurpose.signup,
  }) {
    if (raw == null) return fallback;
    for (final v in OtpPurpose.values) {
      if (v.name == raw) return v;
    }
    return fallback;
  }

  /// Wire format used by backend payloads.
  String get wireName => name;
}
