import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Avatar-Stapel für Teilnehmer (live aus activity_participants).
class ParticipantAvatarStack extends StatelessWidget {
  const ParticipantAvatarStack({
    super.key,
    required this.count,
    required this.hostInitial,
    this.avatarUrls = const [],
    this.maxVisible = 3,
  });

  final int count;
  final String hostInitial;
  final List<String> avatarUrls;
  final int maxVisible;

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return const SizedBox.shrink();
    }

    final visible = count.clamp(0, maxVisible);
    final extra = count > maxVisible ? count - maxVisible : 0;

    return SizedBox(
      width: 28.0 * visible + (extra > 0 ? 20 : 0),
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < visible; i++)
            Positioned(
              left: i * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: _colorForIndex(i),
                backgroundImage: i < avatarUrls.length
                    ? CachedNetworkImageProvider(avatarUrls[i])
                    : null,
                child: i >= avatarUrls.length
                    ? Text(
                        i == 0
                            ? hostInitial[0].toUpperCase()
                            : String.fromCharCode(65 + (i * 7) % 26),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      )
                    : null,
              ),
            ),
          if (extra > 0)
            Positioned(
              left: visible * 18.0,
              child: CircleAvatar(
                radius: 14,
                backgroundColor: AppColors.surfaceTint,
                child: Text(
                  '+$extra',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Color _colorForIndex(int index) => switch (index) {
        0 => AppColors.seed,
        1 => AppColors.secondary,
        _ => AppColors.tertiary,
      };
}
