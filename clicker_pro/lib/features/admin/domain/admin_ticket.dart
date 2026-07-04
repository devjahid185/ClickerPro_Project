// lib/features/admin/domain/admin_ticket.dart
//
// Admin-side view of a support ticket. Maps onto `SupportTicket` as returned
// by `SupportController::adminIndex` (eager-loads the `user` relation).

class AdminTicket {
  const AdminTicket({
    required this.id,
    required this.subject,
    required this.body,
    required this.status,
    this.adminReply,
    this.userName,
    this.userEmail,
    this.createdAt,
  });

  final String id;
  final String subject;
  final String body;
  final String status;
  final String? adminReply;
  final String? userName;
  final String? userEmail;
  final DateTime? createdAt;

  bool get isOpen => status == 'OPEN' || status == 'IN_PROGRESS';

  factory AdminTicket.fromJson(Map<String, dynamic> json) {
    String? s(Object? v) {
      final str = v?.toString().trim();
      return (str == null || str.isEmpty) ? null : str;
    }

    final user = json['user'];
    final userMap = (user is Map) ? user.cast<String, dynamic>() : null;

    return AdminTicket(
      id: (json['id'] ?? '').toString(),
      subject: (json['subject'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      status: (json['status'] ?? 'OPEN').toString(),
      adminReply: s(json['admin_reply'] ?? json['adminReply']),
      userName: s(userMap?['name'] ?? userMap?['fullName']),
      userEmail: s(userMap?['email']),
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'] ?? '').toString()),
    );
  }
}
