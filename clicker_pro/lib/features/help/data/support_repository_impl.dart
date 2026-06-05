// lib/features/help/data/support_repository_impl.dart

import '../domain/faq_entry.dart';
import '../domain/support_repository.dart';
import '../domain/support_ticket_draft.dart';
import 'support_api.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl({required SupportApi api}) : _api = api;

  final SupportApi _api;

  @override
  Future<List<FaqEntry>> faqs() => _api.faqs();

  @override
  Future<String> submitTicket(SupportTicketDraft draft) =>
      _api.submitTicket(draft);
}
