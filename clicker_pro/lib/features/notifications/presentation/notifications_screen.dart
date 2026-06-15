// lib/features/notifications/presentation/notifications_screen.dart
//
// In-app notifications inbox.  Tap a row → optimistic mark-read + (if a
// deeplink is present) navigate via Navigator.pushNamed.  Pull-to-refresh
// re-fetches the list।
//
// FCM push wiring is a future slice; this surface is the canonical
// destination once a push is tapped — the deeplink handler will
// eventually push us straight to a `bookingDetail` / `reEditRequests`
// route, but for now we just open the inbox।

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../core/navigation/deeplink_router.dart';
import '../../../shared/states/empty_state.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';
import '../application/notification_providers.dart';
import 'widgets/notification_row.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loc = AppLocalizations.of(context);
    final lang = 'en';
    final async = ref.watch(notificationInboxControllerProvider);
    final unread = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Row(
          children: [
            Text(
              loc.notifications_title,
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Poppins',
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (unread > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  loc.notifications_unread_badge(unread),
                  style: TextStyle(
                    color: AppColors.film,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.orange,
        backgroundColor: AppColors.voidLight,
        onRefresh: () async {
          await ref
              .read(notificationInboxControllerProvider.notifier)
              .refresh();
        },
        child: async.when(
          loading: () => const Center(child: LensLoader()),
          error: (_, _) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.75,
                child: ErrorState(
                  message: loc.notifications_load_failed,
                  onRetry: () => ref
                      .read(notificationInboxControllerProvider.notifier)
                      .refresh(),
                ),
              ),
            ],
          ),
          data: (items) {
            if (items.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.75,
                    child: EmptyState(
                      message:
                          '${loc.notifications_empty_title}\n'
                          '${loc.notifications_empty_subtitle}',
                      icon: Icons.notifications_none_outlined,
                    ),
                  ),
                ],
              );
            }
            return ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: items.length,
              itemBuilder: (_, i) {
                final n = items[i];
                return NotificationRow(
                  notification: n,
                  lang: lang,
                  onTap: () async {
                    // Optimistic mark-read; rollback on failure is handled
                    // inside the controller।
                    if (!n.read) {
                      ref
                          .read(notificationInboxControllerProvider.notifier)
                          .markRead(n.id)
                          .ignore();
                    }
                    final target = DeeplinkRouter.resolve(n.deeplink);
                    if (target != null && context.mounted) {
                      Navigator.of(context).pushNamed(
                        target.routeName,
                        arguments: target.arguments,
                      );
                    }
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
