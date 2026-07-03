import 'package:clicker_pro/features/auth/domain/user_role.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UserRole.fromString', () {
    test('maps ADMIN to webAdmin', () {
      expect(UserRole.fromString('ADMIN'), UserRole.webAdmin);
      expect(UserRole.fromString('admin'), UserRole.webAdmin);
      expect(UserRole.fromString('WebAdmin'), UserRole.webAdmin);
      expect(UserRole.fromString('web_admin'), UserRole.webAdmin);
    });

    test('maps known role strings to the corresponding enum', () {
      expect(UserRole.fromString('OWNER'), UserRole.owner);
      expect(UserRole.fromString('freelancer'), UserRole.freelancer);
      expect(UserRole.fromString('both'), UserRole.both);
      expect(UserRole.fromString('manager'), UserRole.manager);
    });

    test('falls back to owner for unknown values', () {
      expect(UserRole.fromString('UNKNOWN_ROLE'), UserRole.owner);
      expect(UserRole.fromString(null), UserRole.owner);
    });
  });
}
