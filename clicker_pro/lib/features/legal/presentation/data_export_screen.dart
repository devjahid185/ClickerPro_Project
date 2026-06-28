// lib/features/legal/presentation/data_export_screen.dart
//
// Data Export request screen. Single button to fire
// `legalRepository.requestDataExport()`. On success a glass status card
// confirms submission. On error → ErrorState.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/states/error_state.dart';
import '../../../shared/states/lens_loader.dart';
import '../../../theme/app_colors.dart';

class DataExportScreen extends ConsumerStatefulWidget {
  const DataExportScreen({super.key});

  @override
  ConsumerState<DataExportScreen> createState() => _DataExportScreenState();
}

class _DataExportScreenState extends ConsumerState<DataExportScreen> {
  bool _submitting = false;
  bool _submitted = false;
  String? _downloadUrl;
  Object? _error;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final url = await ref.read(legalRepositoryProvider).requestDataExport();
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitted = true;
        _downloadUrl = url.isEmpty ? null : url;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.voidBlack,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.film),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Data Export',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_submitting) return const LensLoader();
    if (_error != null) {
      return ErrorState(
        message:
            'Could not submit your export request. Check your connection and try again.',
        onRetry: _submit,
      );
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.cloud_download_outlined,
                        color: AppColors.orange,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Request your data',
                        style: TextStyle(
                          color: AppColors.film,
                          fontFamily: 'Poppins',
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'We will prepare a bundle of your studio data — profile, '
                  'bookings, payments, gear, and preferences — and email a '
                  'download link when it is ready.',
                  style: TextStyle(
                    color: AppColors.filmDim.withValues(alpha: 0.85),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          if (_submitted) _buildSuccessCard() else _buildRequestButton(),
        ],
      ),
    );
  }

  Widget _buildRequestButton() {
    return SizedBox(
      height: 52,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.orange,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: _submit,
        icon: const Icon(Icons.outbox_outlined, color: Colors.white, size: 18),
        label: Text(
          'Request Data Export',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14.5,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.greenSoft,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_outline, color: AppColors.green),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Submitted',
                  style: TextStyle(
                    color: AppColors.film,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "We'll email you the bundle when it's ready.",
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.9),
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_downloadUrl != null) ...[
            const SizedBox(height: 12),
            SelectableText(
              _downloadUrl!,
              style: TextStyle(
                color: AppColors.gold,
                fontFamily: 'Montserrat',
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
