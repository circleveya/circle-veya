import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'sidebar_navigation.dart';
import 'web_header.dart';
import 'web_right_panel.dart';
import 'web_shell_destination.dart';

/// Responsives 3-Spalten-Layout für Flutter Web (Desktop).
class WebLayoutScaffold extends StatelessWidget {
  const WebLayoutScaffold({
    super.key,
    required this.destination,
    required this.onDestinationChanged,
    required this.body,
    this.showRightPanel = true,
    this.notificationCount = 0,
    this.unreadChatCount = 0,
  });

  final WebShellDestination destination;
  final ValueChanged<WebShellDestination> onDestinationChanged;
  final Widget body;
  final bool showRightPanel;
  final int notificationCount;
  final int unreadChatCount;

  /// Ab dieser Breite wird das 3-Spalten-Layout aktiv.
  static const double desktopBreakpoint = AppColors.webBreakpoint;

  static bool isDesktop(BuildContext context) {
    return MediaQuery.sizeOf(context).width >= desktopBreakpoint;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= desktopBreakpoint;
    final showRight = showRightPanel && isWide && width >= 1100;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SidebarNavigation(
            selected: destination,
            onSelected: onDestinationChanged,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                WebHeader(
                  onNavigate: onDestinationChanged,
                  notificationCount: notificationCount,
                  unreadChatCount: unreadChatCount,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ColoredBox(
                          color: Theme.of(context).colorScheme.surface,
                          child: body,
                        ),
                      ),
                      if (showRight)
                        WebRightPanel(destination: destination),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
