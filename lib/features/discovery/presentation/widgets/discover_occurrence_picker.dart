import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../activities/domain/entities/activity.dart';
import '../../domain/discover_feed_item.dart';

/// Bottom-Sheet zur Auswahl eines Termins aus einer Kursreihe.
Future<DiscoverableActivity?> showDiscoverOccurrencePicker(
  BuildContext context,
  DiscoverFeedItem item,
) {
  if (!item.isGrouped) {
    return Future.value(item.primary);
  }

  final dateFormat = DateFormat('dd.MM.yyyy · HH:mm');

  return showModalBottomSheet<DiscoverableActivity>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      return SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 4),
              child: Text(
                item.primary.title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            if (item.primary.locationName != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: Text(
                  item.primary.locationName!,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: item.occurrences.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final occurrence = item.occurrences[index];
                  final label = occurrence.dateTime == null
                      ? 'Flexibel'
                      : dateFormat.format(occurrence.dateTime!.toLocal());

                  return ListTile(
                    leading: const Icon(Icons.event_outlined),
                    title: Text(label),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pop(occurrence),
                  );
                },
              ),
            ),
          ],
        ),
      );
    },
  );
}
