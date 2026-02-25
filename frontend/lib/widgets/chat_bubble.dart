// Chat bubble widget

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../services/translation_service.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isUser;
  final DateTime timestamp;

  const ChatBubble({
    super.key,
    required this.message,
    required this.isUser,
    required this.timestamp,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedMessage = _normalizeMessage(message);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            isUser
                ? Text(
                    normalizedMessage,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : MarkdownBody(
                    data: normalizedMessage,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
                      p: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      listBullet: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      code: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withAlpha(120),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
            const SizedBox(height: 4),
            Text(
              _formatTime(context, timestamp),
              style: TextStyle(
                fontSize: 12,
                color: isUser
                    ? Theme.of(context).colorScheme.onPrimary.withAlpha(128)
                    : Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant.withAlpha(128),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(BuildContext context, DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return tr(context, 'now');
    } else if (difference.inHours < 1) {
      return tr(context, 'minutesAgo').replaceAll('{n}', '${difference.inMinutes}');
    } else if (difference.inDays < 1) {
      return tr(context, 'hoursAgo').replaceAll('{n}', '${difference.inHours}');
    } else {
      return '${dateTime.month}/${dateTime.day}';
    }
  }

  String _normalizeMessage(String text) {
    return text
        .replaceAll(r'\r\n', '\n')
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\t', '\t');
  }
}
