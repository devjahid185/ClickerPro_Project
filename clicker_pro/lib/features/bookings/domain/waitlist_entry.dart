enum WaitlistStatus { waiting, contacted, booked, expired }

class WaitlistEntry {
  final String id;
  final String ownerId;
  final String clientName;
  final String phone;
  final DateTime preferredDate;
  final String? note;

  /// Optional Facebook profile / page link for the client, so the studio can
  /// reach them on Messenger as well as by phone. Persisted server-side once
  /// the `facebook_link` column ships.
  final String? facebookLink;

  final WaitlistStatus status;

  const WaitlistEntry({
    required this.id,
    required this.ownerId,
    required this.clientName,
    required this.phone,
    required this.preferredDate,
    this.note,
    this.facebookLink,
    this.status = WaitlistStatus.waiting,
  });

  WaitlistEntry copyWith({
    String? id,
    String? ownerId,
    String? clientName,
    String? phone,
    DateTime? preferredDate,
    String? note,
    String? facebookLink,
    WaitlistStatus? status,
  }) {
    return WaitlistEntry(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      clientName: clientName ?? this.clientName,
      phone: phone ?? this.phone,
      preferredDate: preferredDate ?? this.preferredDate,
      note: note ?? this.note,
      facebookLink: facebookLink ?? this.facebookLink,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'ownerId': ownerId,
      'clientName': clientName,
      'phone': phone,
      'preferredDate': preferredDate.toIso8601String(),
      if (note != null) 'note': note,
      if (facebookLink != null) 'facebookLink': facebookLink,
      'status': status.name,
    };
  }

  factory WaitlistEntry.fromJson(Map<String, dynamic> json) {
    return WaitlistEntry(
      id: json['id'] as String,
      ownerId: json['ownerId'] as String? ?? '',
      clientName: json['clientName'] as String,
      phone: json['phone'] as String,
      preferredDate: DateTime.parse(json['preferredDate'] as String),
      note: json['note'] as String?,
      // Accept both camelCase (app) and snake_case (Laravel) keys.
      facebookLink:
          json['facebookLink'] as String? ?? json['facebook_link'] as String?,
      status: WaitlistStatus.values.firstWhere(
        (s) => s.name == json['status'] as String,
        orElse: () => WaitlistStatus.waiting,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! WaitlistEntry) return false;
    return id == other.id &&
        ownerId == other.ownerId &&
        clientName == other.clientName &&
        phone == other.phone &&
        preferredDate == other.preferredDate &&
        note == other.note &&
        facebookLink == other.facebookLink &&
        status == other.status;
  }

  @override
  int get hashCode => Object.hash(
        id,
        ownerId,
        clientName,
        phone,
        preferredDate,
        note,
        facebookLink,
        status,
      );
}
