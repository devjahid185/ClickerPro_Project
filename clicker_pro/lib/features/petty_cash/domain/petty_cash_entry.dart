enum PettyCashCategory { transport, food, print, phone, misc }

class PettyCashEntry {
  final String id;
  final String title;
  final PettyCashCategory category;
  final double amount;
  final DateTime date;

  const PettyCashEntry({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.date,
  });

  PettyCashEntry copyWith({
    String? id,
    String? title,
    PettyCashCategory? category,
    double? amount,
    DateTime? date,
  }) {
    return PettyCashEntry(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'title': title,
      'category': category.name,
      'amount': amount,
      'date': date.toIso8601String(),
    };
  }

  factory PettyCashEntry.fromJson(Map<String, dynamic> json) {
    return PettyCashEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      category: PettyCashCategory.values.firstWhere(
        (c) => c.name == json['category'] as String,
        orElse: () => PettyCashCategory.misc,
      ),
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! PettyCashEntry) return false;
    return id == other.id &&
        title == other.title &&
        category == other.category &&
        amount == other.amount &&
        date == other.date;
  }

  @override
  int get hashCode => Object.hash(id, title, category, amount, date);
}
