import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/chat.dart';

class MessageBubble extends StatelessWidget {
  const MessageBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final timestamp =
        DateFormat('dd.MM.yyyy · HH:mm').format(message.createdAt.toLocal());
    final isMine = message.isMine;
    final alignment = isMine ? Alignment.centerRight : Alignment.centerLeft;
    final color = isMine
        ? AppColors.seed.withValues(alpha: 0.18)
        : theme.colorScheme.surfaceContainerHighest;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(16),
      topRight: const Radius.circular(16),
      bottomLeft: Radius.circular(isMine ? 16 : 4),
      bottomRight: Radius.circular(isMine ? 4 : 16),
    );
    final content = message.content.trim();
    final showCaption = content.isNotEmpty &&
        content != 'Bild' &&
        content != 'GIF' &&
        content != ' ';

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: message.hasMedia
              ? const EdgeInsets.fromLTRB(6, 6, 6, 8)
              : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
          ),
          child: Column(
            crossAxisAlignment:
                isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (!isMine)
                Padding(
                  padding: message.hasMedia
                      ? const EdgeInsets.fromLTRB(8, 4, 8, 4)
                      : EdgeInsets.zero,
                  child: Text(
                    message.senderUsername,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.seed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (message.hasMedia)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: message.messageType == ChatMessageType.gif
                      ? Image.network(
                          message.mediaUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          gaplessPlayback: true,
                          errorBuilder: (_, _, _) => const SizedBox(
                            height: 120,
                            child: Center(
                              child: Icon(Icons.broken_image_outlined),
                            ),
                          ),
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return const SizedBox(
                              height: 160,
                              child: Center(child: CircularProgressIndicator()),
                            );
                          },
                        )
                      : CachedNetworkImage(
                          imageUrl: message.mediaUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          placeholder: (_, _) => const SizedBox(
                            height: 160,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                          errorWidget: (_, _, _) => const SizedBox(
                            height: 120,
                            child:
                                Center(child: Icon(Icons.broken_image_outlined)),
                          ),
                        ),
                ),
              if (showCaption) ...[
                if (message.hasMedia) const SizedBox(height: 6),
                Padding(
                  padding: message.hasMedia
                      ? const EdgeInsets.symmetric(horizontal: 8)
                      : EdgeInsets.zero,
                  child: Text(
                    content,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.brandNavy,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 4),
              Padding(
                padding: message.hasMedia
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : EdgeInsets.zero,
                child: Text(
                  timestamp,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
