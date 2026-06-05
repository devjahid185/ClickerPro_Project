// lib/features/gear/domain/gear_item.dart
//
// Gear item — camera, lens, flash, etc.  Backend `presentGear` shape:
//   { id, name, brand, category, condition?, value, addedAt? }

class GearItem {
  final String id;
  final String name;
  final String? brand;
  final String category;
  final String? condition;
  final double value;
  final DateTime? addedAt;

  const GearItem({
    required this.id,
    required this.name,
    this.brand,
    required this.category,
    this.condition,
    required this.value,
    this.addedAt,
  });

  Map<String, dynamic> toCreateJson() => {
    'name': name,
    if (brand != null) 'brand': brand,
    'category': category,
    if (condition != null) 'condition': condition,
    'value': value,
  };

  factory GearItem.fromJson(Map<String, dynamic> json) => GearItem(
    id: (json['id'] ?? '').toString(),
    name: (json['name'] ?? '').toString(),
    brand: json['brand'] as String?,
    category: (json['category'] ?? 'Other').toString(),
    condition: json['condition'] as String?,
    value: (json['value'] as num?)?.toDouble() ?? 0,
    addedAt: json['addedAt'] == null
        ? null
        : DateTime.tryParse(json['addedAt'].toString()),
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is GearItem &&
          id == other.id &&
          name == other.name &&
          brand == other.brand &&
          category == other.category &&
          condition == other.condition &&
          value == other.value &&
          addedAt == other.addedAt);

  @override
  int get hashCode =>
      Object.hash(id, name, brand, category, condition, value, addedAt);
}
