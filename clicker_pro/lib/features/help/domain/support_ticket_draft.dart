// lib/features/help/domain/support_ticket_draft.dart

class SupportTicketDraft {
  final String subject;
  final String message;
  final String priority;
  final String? screenshot;

  const SupportTicketDraft({
    required this.subject,
    required this.message,
    this.priority = 'NORMAL',
    this.screenshot,
  });

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'message': message,
    'priority': priority,
    if (screenshot != null) 'screenshot': screenshot,
  };
}
