import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/activity.dart';

/// Temporäre Auswahl eines Entdecken-Events für die Aktivitäts-Erstellung.
class EventSelection extends Equatable {
  const EventSelection({
    required this.sourceEventId,
    required this.title,
    this.dateTime,
    this.imageUrl,
    this.locationName,
    this.externalUrl,
  });

  factory EventSelection.fromDiscoverable(DiscoverableActivity activity) {
    return EventSelection(
      sourceEventId: activity.id,
      title: activity.title,
      dateTime: activity.dateTime,
      imageUrl: activity.imageUrl,
      locationName: activity.locationName,
      externalUrl: activity.externalUrl,
    );
  }

  final String sourceEventId;
  final String title;
  final DateTime? dateTime;
  final String? imageUrl;
  final String? locationName;
  final String? externalUrl;

  @override
  List<Object?> get props => [
        sourceEventId,
        title,
        dateTime,
        imageUrl,
        locationName,
        externalUrl,
      ];
}

class EventSelectionController extends Notifier<EventSelection?> {
  @override
  EventSelection? build() => null;

  void select(EventSelection selection) => state = selection;

  void selectFromActivity(DiscoverableActivity activity) {
    state = EventSelection.fromDiscoverable(activity);
  }

  void clear() => state = null;
}

final eventSelectionProvider =
    NotifierProvider<EventSelectionController, EventSelection?>(
  EventSelectionController.new,
);
