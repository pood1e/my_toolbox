import 'package:app_core/di.dart';
import 'package:app_core/route.dart';

import 'ui/pages/theme_settings_page.dart';

part 'providers.g.dart';

@riverpod
GoRoute themeSettingsRoute(Ref ref) {
  return GoRoute(
    path: AppRoutes.themeSettingsPart,
    builder: (_, _) => ThemeSettingsPage(),
  );
}
