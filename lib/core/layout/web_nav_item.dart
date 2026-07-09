import 'package:flutter/material.dart';

/// Navigationseinträge der Web-Sidebar.
enum WebNavItem {
  feed,
  discover,
  create,
  myActivities,
  friends,
  chats,
  gallery;

  String get label => switch (this) {
        feed => 'Feed',
        discover => 'Entdecken',
        create => 'Aktivität erstellen',
        myActivities => 'Meine Aktivitäten',
        friends => 'Freunde',
        chats => 'Chats',
        gallery => 'Galerie',
      };

  IconData get icon => switch (this) {
        feed => Icons.dynamic_feed_outlined,
        discover => Icons.explore_outlined,
        create => Icons.add_circle_outline,
        myActivities => Icons.event_outlined,
        friends => Icons.people_outline,
        chats => Icons.chat_outlined,
        gallery => Icons.photo_library_outlined,
      };

  IconData get selectedIcon => switch (this) {
        feed => Icons.dynamic_feed,
        discover => Icons.explore,
        create => Icons.add_circle,
        myActivities => Icons.event,
        friends => Icons.people,
        chats => Icons.chat,
        gallery => Icons.photo_library,
      };

  bool get isPrimary => this == create;

  static const mainItems = [
    WebNavItem.feed,
    WebNavItem.discover,
    WebNavItem.create,
    WebNavItem.myActivities,
    WebNavItem.friends,
    WebNavItem.chats,
    WebNavItem.gallery,
  ];
}
