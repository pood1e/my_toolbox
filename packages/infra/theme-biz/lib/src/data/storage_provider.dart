import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import 'impl/theme_settings_storage_impl.dart';
import 'theme_settings_storage.dart';

part 'storage_provider.g.dart';

@riverpod
Future<ThemeSettingsStorage> themeSettingsStorage(Ref ref) async {
  final kv = await ref.watch(globalKvStoreProvider('theme').future);
  return ThemeSettingsStorageImpl(store: kv);
}
