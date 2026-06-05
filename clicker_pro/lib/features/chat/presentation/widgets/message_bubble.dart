// lib/features/chat/presentation/widgets/message_bubble.dart

import 'package:flutter/material.dart';

import '../../../../core/format/booking_format.dart';
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

  @override
  Widget build(BuildContext context) {
    final align = isSelf ? Alignment.centerRight : Alignment.centerLeft;
    final bubbleColour = isSelf ? AppColors.orange : AppColors.glass;
    final borderColour = isSelf ? AppColors.orange : AppColors.glassBorder;
    final textColour = isSelf ? AppColors.film : AppColors.filmDim;

    return Align(
      alignment: align,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: bubbleColour,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(14),
              topRight: const Radius.circular(14),
              bottomLeft: Radius.circular(isSelf ? 14 : 4),
              bottomRight: Radius.circular(isSelf ? 4 : 14),
            ),
            border: Border.all(color: borderColour),
          ),
          child: Column(
            crossAxisAlignment: isSelf
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
            children: [
              if (!isSelf && (message.senderName?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    message.senderName!,
                    style: const TextStyle(
                      color: AppColors.gold,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Text(
                message.text,
                style: TextStyle(color: textColour, fontSize: 14, height: 1.4),
              ),
              const SizedBox(height: 2),
              Text(
                BookingFormat.relative(message.sentAt, lang: lang),
                style: TextStyle(
                  color: isSelf
                      ? Colors.white.withValues(alpha: 0.7)
                      : AppColors.filmMuted,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
