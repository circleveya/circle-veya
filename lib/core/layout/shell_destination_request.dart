import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'web_shell_destination.dart';

/// Request an HomeShell, zu einem Ziel zu wechseln (z.B. nach Event-Übernahme).
class ShellDestinationRequestController
    extends Notifier<WebShellDestination?> {
  @override
  WebShellDestination? build() => null;

  void goTo(WebShellDestination destination) => state = destination;

  void clear() => state = null;
}

final shellDestinationRequestProvider = NotifierProvider<
    ShellDestinationRequestController, WebShellDestination?>(
  ShellDestinationRequestController.new,
);
