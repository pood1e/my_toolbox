/// 全局路由表
library;

abstract class AppRoutes {
  /// home
  static const String home = dashboard;

  /// dashboard
  static const String dashboard = '/';

  /// launcher
  static const String launcher = '/launcher';

  /// settings
  static const String settings = '/settings';
  static const String themeSettingsPart = 'theme';
  static const String syncSettingsPart = 'sync';

  static const String login = '/login';
  static const String register = '/register';

  /// more features
  static const String schedule = '/schedule';
  static const String inventory = '/inventory';
  static const String notes = '/notes';
}
