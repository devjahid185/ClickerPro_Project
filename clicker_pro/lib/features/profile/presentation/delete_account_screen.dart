// lib/features/profile/presentation/delete_account_screen.dart
//
// Two-step Delete Account flow with a 7-day grace window.
//
// Step 1 — Consequences screen with a red "Continue" CTA.
// Step 2 — Type-DELETE confirmation. Confirm button enabled only when the
//          input exactly equals "DELETE".
//
// On confirm:
//   1. authRepository.requestDeleteAccount()  → returns deletedAt (now + 7d)
//   2. kvStore.writeString(KvKeys.pendingDeleteUntil, deletedAt.toIso8601String())
//   3. sessionController.logout()
//   4. Navigator.pushNamedAndRemoveUntil(RouteNames.login, ...)
//
// LoginScreen reads the marker on init and shows a banner with a
// "Sign in to cancel" link. After a successful login while the marker is
// present, the controller fires `cancelDeleteAccount()` and clears the
// marker.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/route_names.dart';
import '../../../core/providers.dart';
import '../../../core/storage/kv_store.dart';
import '../../../theme/app_colors.dart';
import '../../auth/application/session_controller.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  int _step = 0; // 0 = consequences, 1 = type-DELETE confirm
  final _confirmController = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _confirmController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _confirmController.dispose();
    super.dispose();
  }

  bool get _canConfirm => _confirmController.text == 'DELETE' && !_submitting;

  Future<void> _handleConfirm() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      final deletedAt = await ref
          .read(authRepositoryProvider)
          .requestDeleteAccount();
      await ref
          .read(kvStoreProvider)
          .writeString(KvKeys.pendingDeleteUntil, deletedAt.toIso8601String());
      await ref.read(sessionControllerProvider.notifier).logout();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushNamedAndRemoveUntil(RouteNames.login, (route) => false);
    } catch (_) {
      if (!mounted) return;
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not submit deletion request. Try again.'),
          backgroundColor: AppColors.voidElevated,
          behavior: SnackBarBehavior.floating,
        ),
      );
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
          onPressed: () {
            if (_step == 1) {
              setState(() => _step = 0);
            } else {
              Navigator.of(context).maybePop();
            }
          },
        ),
        title: Text(
          'Delete account?',
          style: TextStyle(
            color: AppColors.film,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: _step == 0 ? _buildConsequences() : _buildConfirm(),
        ),
      ),
    );
  }

  Widget _buildConsequences() {
    return SingleChildScrollView(
      key: const ValueKey('step-consequences'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Delete account?',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 32,
              fontWeight: FontWeight.w600,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Your account will be marked for deletion. You have a 7-day '
            'grace window to sign back in and cancel. After that, all your '
            'data is permanently purged from our systems.',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.9),
              fontSize: 14,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.glass,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What gets deleted',
                  style: TextStyle(
                    color: AppColors.film,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: 0.4,
                  ),
                ),
                SizedBox(height: 12),
                _Bullet(text: 'Company settings, gear, preferences'),
                _Bullet(text: 'All bookings, payments, invoices'),
                _Bullet(text: 'Team invites and chat history'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            height: 52,
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _step = 1),
              child: const Text(
                'Continue',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14.5,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirm() {
    return SingleChildScrollView(
      key: const ValueKey('step-confirm'),
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Confirm by typing DELETE',
            style: TextStyle(
              color: AppColors.film,
              fontFamily: 'Poppins',
              fontSize: 26,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This last step protects against accidental deletions.',
            style: TextStyle(
              color: AppColors.filmDim.withValues(alpha: 0.9),
              fontSize: 13.5,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 22),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            child: TextField(
              controller: _confirmController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: TextStyle(
                color: AppColors.film,
                fontFamily: 'Montserrat',
                fontSize: 16,
                letterSpacing: 2,
              ),
              decoration: InputDecoration(
                hintText: 'DELETE',
                hintStyle: TextStyle(
                  color: AppColors.filmDim.withValues(alpha: 0.55),
                  fontFamily: 'Montserrat',
                  letterSpacing: 2,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.filmDim,
                      side: BorderSide(
                        color: Colors.black.withValues(alpha: 0.18),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).maybePop(),
                    child: const Text('Cancel'),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 52,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.red,
                      disabledBackgroundColor: AppColors.red.withValues(
                        alpha: 0.35,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _canConfirm ? _handleConfirm : null,
                    child: _submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            'Confirm Deletion',
                            style: TextStyle(
                              color: AppColors.film,
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.orange,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: AppColors.filmDim,
                fontSize: 13.5,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
