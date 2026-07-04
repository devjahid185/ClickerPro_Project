// lib/features/admin/domain/admin_setting.dart
//
// One row of the admin settings API (`SettingsController::index`) — a
// key/value pair with the server-side default shown as a hint when no value
// has been saved yet. Secrets arrive masked (empty value) and are only
// overwritten when a new value is sent.

class AdminSetting {
  const AdminSetting({
    required this.key,
    required this.value,
    this.defaultValue,
    this.isSecret = false,
    this.hasValue = false,
  });

  final String key;
  final String value;
  final String? defaultValue;
  final bool isSecret;
  final bool hasValue;

  factory AdminSetting.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString();
      return (str == null || str.isEmpty) ? null : str;
    }

    return AdminSetting(
      key: (json['key'] ?? '').toString(),
      value: (json['value'] ?? '').toString(),
      defaultValue: s(json['defaultValue']),
      isSecret: json['isSecret'] == true,
      hasValue: json['hasValue'] == true,
    );
  }
}
