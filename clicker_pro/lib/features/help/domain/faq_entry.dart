// lib/features/help/domain/faq_entry.dart
//
// Single FAQ row.  Backend response shape (controllers/supportController.js):
//   { id, question, answer, category, order, createdAt }

class FaqEntry {
  final String id;
  final String question;
  final String answer;
  final String category;
  final int order;

  const FaqEntry({
    required this.id,
    required this.question,
    required this.answer,
    required this.category,
    required this.order,
  });

  factory FaqEntry.fromJson(Map<String, dynamic> json) => FaqEntry(
    id: (json['id'] ?? '').toString(),
    question: (json['question'] ?? '').toString(),
    answer: (json['answer'] ?? '').toString(),
    category: (json['category'] ?? 'General').toString(),
    order: (json['order'] as num?)?.toInt() ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FaqEntry &&
          id == other.id &&
          question == other.question &&
          answer == other.answer &&
          category == other.category &&
          order == other.order);

  @override
  int get hashCode => Object.hash(id, question, answer, category, order);
}
