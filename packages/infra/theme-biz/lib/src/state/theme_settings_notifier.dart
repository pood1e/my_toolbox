import 'package:app_core/di.dart';

import '../data/storage_provider.dart';
import '../domain/theme_settings.dart';

part 'theme_settings_notifier.g.dart';

@Riverpod(keepAlive: true)
class ThemeSettingsNotifier extends _$ThemeSettingsNotifier {
  @override
  Future<ThemeSettings> build() async {
    final repo = await ref.watch(themeSettingsStorageProvider.future);
    return await repo.load();
  }

  Future<void> updateTheme(ThemeSettings settings) async {
    final old = await future;
    if (old == settings) {
      return;
    }
    state = AsyncValue.data(settings);
    final repo = await ref.read(themeSettingsStorageProvider.future);
    await repo.save(settings);
  }
}
