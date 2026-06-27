import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/color_constants.dart';
import '../../models/message_model.dart';

/// A single chat bubble. Mine = right-aligned accent; theirs = left-aligned
/// surfaceVariant. For my bubbles a status tick reflects sending/sent/read/failed.
class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;
  final VoidCallback? onRetry;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isMine ? AppColors.accent : AppColors.surfaceVariant;
    final textColor = isMine ? AppColors.onAccent : AppColors.onSurface;
    final time = DateFormat('HH:mm').format(message.createdAt.toLocal());

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        onTap: message.status == MessageStatus.failed ? onRetry : null,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(16),
              topRight: const Radius.circular(16),
              bottomLeft: Radius.circular(isMine ? 16 : 4),
              bottomRight: Radius.circular(isMine ? 4 : 16),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                message.text,
                style: TextStyle(color: textColor, fontSize: 15),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    message.status == MessageStatus.failed ? 'Tap to retry' : time,
                    style: TextStyle(
                      color: message.status == MessageStatus.failed
                          ? AppColors.error
                          : textColor.withValues(alpha: 0.7),
                      fontSize: 10,
                    ),
                  ),
                  if (isMine) ...[
                    const SizedBox(width: 4),
                    _statusIcon(textColor),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusIcon(Color color) {
    switch (message.status) {
      case MessageStatus.sending:
        return Icon(Icons.access_time, size: 12, color: color.withValues(alpha: 0.7));
      case MessageStatus.sent:
      case MessageStatus.delivered:
        return Icon(Icons.done, size: 14, color: color.withValues(alpha: 0.7));
      case MessageStatus.read:
        return const Icon(Icons.done_all, size: 14, color: AppColors.accentBlueLight);
      case MessageStatus.failed:
        return const Icon(Icons.error_outline, size: 14, color: AppColors.error);
    }
  }
}
