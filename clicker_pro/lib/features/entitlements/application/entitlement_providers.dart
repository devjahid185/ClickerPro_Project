import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../domain/entitlements.dart';

/// Fetches the current user's entitlements once and caches them. Falls back to
/// [Entitlements.allUnlocked] on any error so a transient network failure
/// never locks a user out of a feature they should have.
final entitlementsProvider = FutureProvider<Entitlements>((ref) async {
  try {
    final client = ref.read(apiClientProvider);
    final r = await client.get('/api/entitlements') as Map<String, dynamic>;
    final data = (r['data'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Entitlements.fromJson(data);
  } catch (_) {
    return Entitlements.allUnlocked;
  }
});

/// Synchronous helper for widgets: returns whether [featureKey] is unlocked
/// right now. While the fetch is in flight (or on error) it returns true
/// (permissive) so the UI never flickers a lock during load.
final isFeatureUnlockedProvider = Provider.family<bool, String>((ref, featureKey) {
  final async = ref.watch(entitlementsProvider);
  return async.maybeWhen(
    data: (e) => e.isUnlocked(featureKey),
    orElse: () => true,
  );
});

/// Feature keys — keep in sync with backend `seedFeatures.js`.
class Features {
  static const reminders = 'reminders';
  static const pdfExport = 'pdf_export';
  static const waitlist = 'waitlist';
  static const analytics = 'analytics';
  static const team = 'team';
  static const publicBooking = 'public_booking';
  static const gearRent = 'gear_rent';
  static const deliveryChecklist = 'delivery_checklist';
}
