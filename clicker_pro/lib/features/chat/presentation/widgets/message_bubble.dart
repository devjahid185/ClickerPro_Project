// lib/features/chat/presentation/widgets/message_bubble.dart
//
// One chat message row, matching the .dc.html MOD-40 design:
//
//   incoming — 26px tinted initials avatar · sender name over a white
//              bubble (radius 14/14/14/4) · time below
//   outgoing — solid orange bubble (radius 14/14/4/14, white text) with
//              "9:42 · Seen N" meta under it

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../theme/app_colors.dart';
import '../../domain/chat_message.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isSelf,
    required this.lang,
  });

  final ChatMessage message;
  final bool isSelf;
  final String lang;

  /// Stable avatar tint per sender, drawn from the design's role palette.
  (Color, Color) get _senderTint {
    final palette = [
      (AppColors.greenSoft, AppColors.green),
      (AppColors.purpleSoft, AppColors.purple),
      (AppColors.orangeSoft, AppColors.primary700),
      (AppColors.goldSoft, AppColors.gold),
    ];
    return palette[message.senderId.hashCode.abs() % palette.length];
  }

  String get _initials {
    final parts = (message.senderName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  String get _time => DateFormat('h:mm a').format(message.sentAt.toLocal());

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: isSelf ? _outgoing(maxWidth) : _incoming(maxWidth),
    );
  }

  Widget _outgoing(double maxWidth) {
    // Read receipt: "Seen N" once other members have read it; a plain
    // check for delivered-but-unseen (optimistic local rows show nothing).
    final isLocal = message.id.startsWith('_local-');
    final meta = message.seenCount > 0
        ? '$_time · Seen ${message.seenCount}'
        : _time;

    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 13,
                vertical: 10,
              ),
              decoration: const BoxDecoration(
                color: AppColors.primary500,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(4),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
            ),
            const SizedBox(height: 3),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  meta,
                  style: TextStyle(
                    color: AppColors.filmMuted,
                    fontSize: 10,
                  ),
                ),
                if (!isLocal && message.seenCount == 0) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.check_rounded,
                    size: 12,
                    color: AppColors.filmMuted,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _incoming(double maxWidth) {
    final (tintBg, tintFg) = _senderTint;

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tintBg,
              ),
              alignment: Alignment.center,
              child: Text(
                _initials,
                style: TextStyle(
                  color: tintFg,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.senderName?.isNotEmpty ?? false)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 3),
                      child: Text(
                        message.senderName!,
                        style: TextStyle(
                          color: AppColors.filmMuted,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 13,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: Border.all(color: AppColors.line(0.05)),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(14),
                        topRight: Radius.circular(14),
                        bottomLeft: Radius.circular(4),
                        bottomRight: Radius.circular(14),
                      ),
                    ),
                    child: Text(
                      message.text,
                      style: TextStyle(
                        color: AppColors.film,
                        fontSize: 13.5,
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Padding(
                    padding: const EdgeInsets.only(left: 2),
                    child: Text(
                      _time,
                      style: TextStyle(
                        color: AppColors.filmMuted,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
