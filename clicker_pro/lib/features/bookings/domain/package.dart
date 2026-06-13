// lib/features/bookings/domain/package.dart
//
// Domain entity for a Package — a reusable bundle of price + coverage
// hours + inclusions that the booking edit screen can apply to a new
// booking instead of typing custom fields.
//
// Pure Dart — no Flutter, Drift, or Riverpod imports.
//
// Source of truth: `.kiro/specs/bookings-module/design.md` → "Data Models"
// section. Validates Requirements 13.11.

/// A reusable booking package owned by a studio.
///
/// Instances are immutable; use [copyWith] to derive modified copies.
class Package {
  /// Local UUID, generated client-side.
  final String id;

  /// Server-assigned id, populated on first successful sync.
  final String? remoteId;

  /// Studio scope — packages are not shared across studios.
  final String studioId;

  /// Display name (1..80 chars).
  final String name;

  /// Base price for the package. Currency formatting at display time.
  final double basePrice;

  /// Discount subtracted from [basePrice] to compute [netPrice].
  final double discount;

  /// Default coverage hours included in the base price.
  final double? coverageHours;

  /// Per-hour rate billed for time beyond [coverageHours].
  final double? extraHourRate;

  /// Print size label — one of "8×10", "10×12", "12×18", "16×24",
  /// "20×30", "24×36", or a custom string.
  final String? printSize;

  /// Number of prints included.
  final int? printQuantity;

  /// Album description / count text (e.g. "1 Album", "2 Premium Albums").
  final String? albumText;

  /// Delivery method — "Pendrive", "Google Drive", or "Both".
  final String? deliveryMethod;

  /// Number of trailers per event.
  final int? trailersPerEvent;

  /// Number of full-length videos per event.
  final int? fullVideosPerEvent;

  /// How many photographers this package supplies. Auto-fills the booking
  /// form's photographer slots when the package is selected.
  final int? photographerCount;

  /// How many cinematographers this package supplies.
  final int? cinematographerCount;

  /// Whether the package designates a chief photographer.
  final bool includesChief;

  /// Free-form list of line items / inclusions rendered as bullets.
  final List<String>? items;

  /// Free-form list of inclusion descriptors (legacy; prefer [items]).
  final List<String>? inclusions;

  /// Wall-clock timestamp at first creation.
  final DateTime createdAt;

  /// Most recent edit timestamp; reconciled via last-write-wins.
  final DateTime updatedAt;

  /// True while the package has unsynced changes in the outbox.
  final bool pending;

  /// Net price after discount: `basePrice - discount`.
  double get netPrice => basePrice - discount;

  Package({
    required this.id,
    this.remoteId,
    required this.studioId,
    required this.name,
    required this.basePrice,
    this.discount = 0,
    this.coverageHours,
    this.extraHourRate,
    this.printSize,
    this.printQuantity,
    this.albumText,
    this.deliveryMethod,
    this.trailersPerEvent,
    this.fullVideosPerEvent,
    this.photographerCount,
    this.cinematographerCount,
    this.includesChief = false,
    this.items,
    this.inclusions,
    required this.createdAt,
    required this.updatedAt,
    this.pending = false,
  });

  Package copyWith({
    String? id,
    String? remoteId,
    String? studioId,
    String? name,
    double? basePrice,
    double? discount,
    double? coverageHours,
    double? extraHourRate,
    String? printSize,
    int? printQuantity,
    String? albumText,
    String? deliveryMethod,
    int? trailersPerEvent,
    int? fullVideosPerEvent,
    int? photographerCount,
    int? cinematographerCount,
    bool? includesChief,
    List<String>? items,
    List<String>? inclusions,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? pending,
    bool clearPrintSize = false,
    bool clearPrintQuantity = false,
    bool clearAlbumText = false,
    bool clearDeliveryMethod = false,
    bool clearItems = false,
    bool clearInclusions = false,
  }) {
    return Package(
      id: id ?? this.id,
      remoteId: remoteId ?? this.remoteId,
      studioId: studioId ?? this.studioId,
      name: name ?? this.name,
      basePrice: basePrice ?? this.basePrice,
      discount: discount ?? this.discount,
      coverageHours: coverageHours ?? this.coverageHours,
      extraHourRate: extraHourRate ?? this.extraHourRate,
      printSize: clearPrintSize ? null : (printSize ?? this.printSize),
      printQuantity: clearPrintQuantity
          ? null
          : (printQuantity ?? this.printQuantity),
      albumText: clearAlbumText ? null : (albumText ?? this.albumText),
      deliveryMethod: clearDeliveryMethod
          ? null
          : (deliveryMethod ?? this.deliveryMethod),
      trailersPerEvent: trailersPerEvent ?? this.trailersPerEvent,
      fullVideosPerEvent: fullVideosPerEvent ?? this.fullVideosPerEvent,
      photographerCount: photographerCount ?? this.photographerCount,
      cinematographerCount: cinematographerCount ?? this.cinematographerCount,
      includesChief: includesChief ?? this.includesChief,
      items: clearItems ? null : (items ?? this.items),
      inclusions: clearInclusions ? null : (inclusions ?? this.inclusions),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      pending: pending ?? this.pending,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      if (remoteId != null) 'remoteId': remoteId,
      'studioId': studioId,
      'name': name,
      'basePrice': basePrice,
      'discount': discount,
      if (coverageHours != null) 'coverageHours': coverageHours,
      if (extraHourRate != null) 'extraHourRate': extraHourRate,
      if (printSize != null) 'printSize': printSize,
      if (printQuantity != null) 'printQuantity': printQuantity,
      if (albumText != null) 'albumText': albumText,
      if (deliveryMethod != null) 'deliveryMethod': deliveryMethod,
      if (trailersPerEvent != null) 'trailersPerEvent': trailersPerEvent,
      if (fullVideosPerEvent != null) 'fullVideosPerEvent': fullVideosPerEvent,
      if (photographerCount != null) 'photographerCount': photographerCount,
      if (cinematographerCount != null)
        'cinematographerCount': cinematographerCount,
      'includesChief': includesChief,
      if (items != null) 'items': items,
      if (inclusions != null) 'inclusions': inclusions,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'pending': pending,
    };
  }

  factory Package.fromJson(Map<String, dynamic> json) {
    return Package(
      id: json['id'] as String,
      remoteId: json['remoteId'] as String?,
      studioId: json['studioId'] as String,
      name: json['name'] as String,
      basePrice: (json['basePrice'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      coverageHours: (json['coverageHours'] as num?)?.toDouble(),
      extraHourRate: (json['extraHourRate'] as num?)?.toDouble(),
      printSize: json['printSize'] as String?,
      printQuantity: (json['printQuantity'] as num?)?.toInt(),
      albumText: json['albumText'] as String?,
      deliveryMethod: json['deliveryMethod'] as String?,
      trailersPerEvent: (json['trailersPerEvent'] as num?)?.toInt(),
      fullVideosPerEvent: (json['fullVideosPerEvent'] as num?)?.toInt(),
      photographerCount: (json['photographerCount'] as num?)?.toInt(),
      cinematographerCount: (json['cinematographerCount'] as num?)?.toInt(),
      includesChief: json['includesChief'] as bool? ?? false,
      items: json['items'] == null
          ? null
          : List<String>.from(json['items'] as List),
      inclusions: json['inclusions'] == null
          ? null
          : List<String>.from(json['inclusions'] as List),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      pending: json['pending'] as bool? ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Package) return false;
    return id == other.id &&
        remoteId == other.remoteId &&
        studioId == other.studioId &&
        name == other.name &&
        basePrice == other.basePrice &&
        discount == other.discount &&
        coverageHours == other.coverageHours &&
        extraHourRate == other.extraHourRate &&
        printSize == other.printSize &&
        printQuantity == other.printQuantity &&
        albumText == other.albumText &&
        deliveryMethod == other.deliveryMethod &&
        trailersPerEvent == other.trailersPerEvent &&
        fullVideosPerEvent == other.fullVideosPerEvent &&
        photographerCount == other.photographerCount &&
        cinematographerCount == other.cinematographerCount &&
        includesChief == other.includesChief &&
        _listEquals(items, other.items) &&
        _listEquals(inclusions, other.inclusions) &&
        createdAt == other.createdAt &&
        updatedAt == other.updatedAt &&
        pending == other.pending;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    id,
    remoteId,
    studioId,
    name,
    basePrice,
    discount,
    coverageHours,
    extraHourRate,
    printSize,
    printQuantity,
    albumText,
    deliveryMethod,
    trailersPerEvent,
    fullVideosPerEvent,
    photographerCount,
    cinematographerCount,
    includesChief,
    items == null ? 0 : Object.hashAll(items!),
    inclusions == null ? 0 : Object.hashAll(inclusions!),
    createdAt,
    updatedAt,
    pending,
  ]);

  @override
  String toString() =>
      'Package(id: $id, name: $name, basePrice: $basePrice, discount: $discount)';
}

/// Order-sensitive list equality used for [Package.inclusions].
bool _listEquals<T>(List<T>? a, List<T>? b) {
  if (identical(a, b)) return true;
  if (a == null || b == null) return false;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
