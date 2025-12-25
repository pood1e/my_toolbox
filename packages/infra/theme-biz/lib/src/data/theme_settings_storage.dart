import '../domain/theme_settings.dart';

abstract class ThemeSettingsStorage {
  Future<ThemeSettings> load();

  Future<void> save(ThemeSettings newSettings);
}
