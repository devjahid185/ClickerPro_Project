/// What the current user can access, as resolved by the server
/// (`GET /api/entitlements`). The app gates UI on [isUnlocked]; it never has
/// to reason about plans or flags itself.
class Entitlements {
  final String plan; // FREE | PRO
  final DateTime? planExpiresAt;
  final bool isPro;
  final Map<String, bool> features; // feature key → unlocked?

  const Entitlements({
    required this.plan,
    required this.isPro,
    this.planExpiresAt,
    this.features = const {},
  });

  /// Unlocked if the server says so. Unknown keys default to TRUE so a new
  /// client build that references a not-yet-registered feature never wrongly
  /// locks the user out.
  bool isUnlocked(String key) => features[key] ?? true;

  /// Permissive fallback used before the network call resolves or if it
  /// fails — everything unlocked, so we never block a paying/free user on a
  /// transient error.
  static const Entitlements allUnlocked = Entitlements(
    plan: 'FREE',
    isPro: false,
  );

  factory Entitlements.fromJson(Map<String, dynamic> json) {
    final raw = (json['features'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Entitlements(
      plan: (json['plan'] ?? 'FREE').toString(),
      isPro: json['isPro'] as bool? ?? false,
      planExpiresAt: json['planExpiresAt'] == null
          ? null
          : DateTime.tryParse(json['planExpiresAt'].toString()),
      features: raw.map((k, v) => MapEntry(k, v == true)),
    );
  }
}
