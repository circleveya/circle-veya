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

    final isGif = message.messageType == ChatMessageType.gif;
    final isMedia = message.hasMedia;
    final screenWidth = MediaQuery.sizeOf(context).width;
    // Medien ~ wie eingezeichnet: mittlere Kachel, nicht Vollbreite
    final mediaMaxWidth = (screenWidth * 0.36).clamp(220.0, 280.0);
    final mediaMaxHeight = isGif ? 200.0 : 180.0;
    final bubbleMaxWidth = isMedia ? mediaMaxWidth : screenWidth * 0.75;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: bubbleMaxWidth),
        child: Container(
          margin: EdgeInsets.only(
            top: 4,
            bottom: 4,
            left: isMine ? 48 : 0,
            right: isMine ? 0 : 48,
          ),
          padding: isMedia
              ? const EdgeInsets.fromLTRB(4, 4, 4, 6)
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
                  padding: isMedia
                      ? const EdgeInsets.fromLTRB(6, 2, 6, 4)
                      : EdgeInsets.zero,
                  child: Text(
                    message.senderUsername,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.seed,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (isMedia)
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: mediaMaxWidth,
                      maxHeight: mediaMaxHeight,
                    ),
                    child: isGif
                        ? Image.network(
                            message.mediaUrl!,
                            fit: BoxFit.contain,
                            width: mediaMaxWidth,
                            gaplessPlayback: true,
                            errorBuilder: (_, _, _) => SizedBox(
                              width: mediaMaxWidth,
                              height: 120,
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                            loadingBuilder: (context, child, progress) {
                              if (progress == null) return child;
                              return SizedBox(
                                width: mediaMaxWidth,
                                height: 120,
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              );
                            },
                          )
                        : CachedNetworkImage(
                            imageUrl: message.mediaUrl!,
                            fit: BoxFit.cover,
                            width: mediaMaxWidth,
                            height: mediaMaxHeight,
                            memCacheWidth: 560,
                            placeholder: (_, _) => SizedBox(
                              width: mediaMaxWidth,
                              height: mediaMaxHeight,
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            ),
                            errorWidget: (_, _, _) => SizedBox(
                              width: mediaMaxWidth,
                              height: 120,
                              child: const Center(
                                child: Icon(Icons.broken_image_outlined),
                              ),
                            ),
                          ),
                  ),
                ),
              if (showCaption) ...[
                if (isMedia) const SizedBox(height: 6),
                Padding(
                  padding: isMedia
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
                padding: isMedia
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
