// lib/features/profile/domain/gear_item.dart
class GearItem {
  const GearItem({
    required this.id,
    required this.userId,
    required this.name,
    this.brand,
    this.remoteId,
    this.addedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? brand;
  final String? remoteId;
  final DateTime? addedAt;
}
