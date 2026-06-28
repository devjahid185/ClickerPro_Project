// lib/core/update/app_update_service.dart
//
// Over-the-air update check for the Android APK (no Play Store needed).
// On app launch it asks the backend (GET /api/app/version) for the latest
// versionCode + APK url. If the server's versionCode is higher than this
// build's AppConfig.appVersionCode, it shows an "Update available" dialog
// that opens the APK url (hosted on the landing site) in the browser /
// installer.
//
// Fail-soft: any network / parse error is swallowed so a flaky check never
// blocks the app. A `forceUpdate` flag makes the dialog non-dismissible.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../env/app_config.dart';
import '../logging/app_logger.dart';
import '../network/api_client.dart';
import '../../theme/app_colors.dart';

class AppUpdateService {
  const AppUpdateService._();

  /// Checks once and, if a newer version exists, shows the update dialog.
  /// Safe to call from a post-frame callback on the dashboard.
  static Future<void> checkAndPrompt(
    BuildContext context,
    ApiClient api,
  ) async {
    try {
      final res = await api.get('/api/app/version');
      final data = (res is Map && res['data'] is Map)
          ? (res['data'] as Map)
          : (res is Map ? res : const {});

      final latest = (data['versionCode'] as num?)?.toInt() ?? 0;
      final apkUrl = (data['apkUrl'] ?? '').toString();
      final versionName = (data['versionName'] ?? '').toString();
      final force = data['forceUpdate'] == true || data['forceUpdate'] == '1';
      final notes = (data['releaseNotes'] ?? '').toString();

      if (latest <= AppConfig.appVersionCode || apkUrl.isEmpty) return;
      if (!context.mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: !force,
        builder: (ctx) => PopScope(
          canPop: !force,
          child: AlertDialog(
            backgroundColor: AppColors.voidElevated,
            title: Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  color: AppColors.orange,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Update available',
                    style: TextStyle(color: AppColors.film, fontSize: 18),
                  ),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  versionName.isNotEmpty
                      ? 'A new version ($versionName) is ready.'
                      : 'A new version of Clicker Pro is ready.',
                  style: TextStyle(color: AppColors.filmDim, fontSize: 13.5),
                ),
                if (notes.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    notes.trim(),
                    style: TextStyle(
                      color: AppColors.filmDim.withValues(alpha: 0.85),
                      fontSize: 12.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              if (!force)
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Later',
                    style: TextStyle(color: AppColors.filmDim),
                  ),
                ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => launchUrl(
                  Uri.parse(apkUrl),
                  mode: LaunchMode.externalApplication,
                ),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: Text('Update now'),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      AppLogger.w('update', 'version check failed: $e');
    }
  }
}
