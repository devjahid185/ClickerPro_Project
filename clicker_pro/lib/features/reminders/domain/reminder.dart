enum ReminderType { payment, delivery, feedback }

enum ReminderChannel { whatsapp, sms }

class Reminder {
  final String id;
  final String bookingId;
  final ReminderType type;
  final DateTime scheduledDate;
  final bool sent;
  final ReminderChannel channel;

  const Reminder({
    required this.id,
    required this.bookingId,
    required this.type,
    required this.scheduledDate,
    this.sent = false,
    required this.channel,
  });

  Reminder copyWith({
    String? id,
    String? bookingId,
    ReminderType? type,
    DateTime? scheduledDate,
    bool? sent,
    ReminderChannel? channel,
  }) {
    return Reminder(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      type: type ?? this.type,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      sent: sent ?? this.sent,
      channel: channel ?? this.channel,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'bookingId': bookingId,
      'type': type.name,
      'scheduledDate': scheduledDate.toIso8601String(),
      'sent': sent,
      'channel': channel.name,
    };
  }

  factory Reminder.fromJson(Map<String, dynamic> json) {
    return Reminder(
      id: json['id'] as String,
      bookingId: json['bookingId'] as String,
      type: ReminderType.values.firstWhere(
        (e) => e.name == json['type'] as String,
        orElse: () => ReminderType.payment,
      ),
      scheduledDate: DateTime.parse(json['scheduledDate'] as String),
      sent: json['sent'] as bool? ?? false,
      channel: ReminderChannel.values.firstWhere(
        (e) => e.name == json['channel'] as String,
        orElse: () => ReminderChannel.whatsapp,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! Reminder) return false;
    return id == other.id &&
        bookingId == other.bookingId &&
        type == other.type &&
        scheduledDate == other.scheduledDate &&
        sent == other.sent &&
        channel == other.channel;
  }

  @override
  int get hashCode =>
      Object.hash(id, bookingId, type, scheduledDate, sent, channel);
}
