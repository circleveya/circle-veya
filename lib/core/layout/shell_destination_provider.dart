import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'web_shell_destination.dart';

/// Aktiver Shell-Tab (Feed, Freunde, Aktivitäten, …).
class ShellDestinationController extends Notifier<WebShellDestination> {
  @override
  WebShellDestination build() => WebShellDestination.discover;

  void set(WebShellDestination destination) => state = destination;
}

final shellDestinationProvider =
    NotifierProvider<ShellDestinationController, WebShellDestination>(
  ShellDestinationController.new,
);
