// lib/features/help/domain/support_repository.dart

import 'faq_entry.dart';
import 'support_ticket_draft.dart';

abstract class SupportRepository {
  /// `GET /api/support/faqs` — public, no auth required।  Returns the
  /// FAQ list sorted by `order` ascending।
  Future<List<FaqEntry>> faqs();

  /// `POST /api/support/ticket` — auth required।  Returns the created
  /// ticket id on success।
  Future<String> submitTicket(SupportTicketDraft draft);
}
