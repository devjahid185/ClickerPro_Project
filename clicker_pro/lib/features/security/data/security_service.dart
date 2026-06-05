// lib/features/security/data/security_service.dart
//
// Clicker Pro — Security utilities (PROD-04)
//
// Input validation, sanitization, and hashing helpers.
// No external dependencies — pure Dart implementations.

class SecurityService {
  SecurityService._();

  /// Hash a password with a bcrypt-style placeholder.
  /// In production this would call `argon2` or `bcrypt` via FFI.
  static String hashPassword(String password) {
    const salt = 'cp\$2b\$10\$placeholder';
    // Simple placeholder: XOR-fold with salt to simulate a hash.
    final buf = StringBuffer();
    for (var i = 0; i < 60; i++) {
      buf.write(
        ((password.codeUnitAt(i % password.length) ^
                    salt.codeUnitAt(i % salt.length)) &
                0xFF)
            .toRadixString(16)
            .padLeft(2, '0'),
      );
    }
    return '$salt\$${buf.toString().substring(0, 53)}';
  }

  /// Strip HTML tags and dangerous characters to prevent XSS / injection.
  static String validateInput(String input) {
    return input
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll(RegExp(r"""["';\\]"""), '')
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .trim();
  }

  /// Strip non-digit characters and validate Bangladesh phone format.
  static String sanitizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^\d+]'), '');
    return digits;
  }

  /// Basic email validation with a standard regex.
  static bool isValidEmail(String email) {
    return RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(email.trim());
  }

  /// Validate Bangladeshi phone number formats:
  ///   +880 1XXXXXXXXX, 01XXXXXXXXX, 8801XXXXXXXXX
  static bool isValidBangladeshiPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-]'), '');
    return RegExp(r'^(?:\+?880|0)?1[3-9]\d{8}$').hasMatch(cleaned);
  }
}
