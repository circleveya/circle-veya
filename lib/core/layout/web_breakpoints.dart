/// Responsive Breakpoints für die Web-App.
abstract final class WebBreakpoints {
  static const double compact = 900;
  static const double desktop = 1200;

  static bool isCompact(double width) => width < compact;
  static bool isDesktop(double width) => width >= desktop;
  static bool showRightPanel(double width) => width >= desktop;
  static bool showSidebar(double width) => width >= compact;
}
