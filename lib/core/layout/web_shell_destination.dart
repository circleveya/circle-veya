import 'package:flutter/material.dart';

/// Navigationsziele der Web-Sidebar.
enum WebShellDestination {
  create,
  discover,
  feed,
  myActivities,
  groups,
  messages,
  friends,
  memories,
  challenges,
  profile,
  settings,
}

extension WebShellDestinationX on WebShellDestination {
  String get label => switch (this) {
        WebShellDestination.create => 'Aktivität erstellen',
        WebShellDestination.discover => 'Entdecken',
        WebShellDestination.feed => 'Feed',
        WebShellDestination.myActivities => 'Meine Aktivitäten',
        WebShellDestination.groups => 'Kreise',
        WebShellDestination.messages => 'Nachrichten',
        WebShellDestination.friends => 'Freunde',
        WebShellDestination.memories => 'Erinnerungen',
        WebShellDestination.challenges => 'Challenges',
        WebShellDestination.profile => 'Profil',
        WebShellDestination.settings => 'Einstellungen',
      };

  IconData get icon => switch (this) {
        WebShellDestination.create => Icons.add_circle_outline,
        WebShellDestination.discover => Icons.explore_outlined,
        WebShellDestination.feed => Icons.dynamic_feed_outlined,
        WebShellDestination.myActivities => Icons.event_outlined,
        WebShellDestination.groups => Icons.groups_outlined,
        WebShellDestination.messages => Icons.chat_bubble_outline,
        WebShellDestination.friends => Icons.people_outline,
        WebShellDestination.memories => Icons.photo_library_outlined,
        WebShellDestination.challenges => Icons.emoji_events_outlined,
        WebShellDestination.profile => Icons.person_outline,
        WebShellDestination.settings => Icons.settings_outlined,
      };

  IconData get selectedIcon => switch (this) {
        WebShellDestination.create => Icons.add_circle,
        WebShellDestination.discover => Icons.explore,
        WebShellDestination.feed => Icons.dynamic_feed,
        WebShellDestination.myActivities => Icons.event,
        WebShellDestination.groups => Icons.groups,
        WebShellDestination.messages => Icons.chat_bubble,
        WebShellDestination.friends => Icons.people,
        WebShellDestination.memories => Icons.photo_library,
        WebShellDestination.challenges => Icons.emoji_events,
        WebShellDestination.profile => Icons.person,
        WebShellDestination.settings => Icons.settings,
      };
}

/// Haupt-Navigation der Sidebar (ohne CTA „Erstellen“).
const kWebSidebarMainNav = [
  WebShellDestination.discover,
  WebShellDestination.feed,
  WebShellDestination.myActivities,
  WebShellDestination.groups,
  WebShellDestination.messages,
  WebShellDestination.friends,
  WebShellDestination.memories,
  WebShellDestination.challenges,
];

const kWebSidebarFooterNav = [
  WebShellDestination.profile,
  WebShellDestination.settings,
];
