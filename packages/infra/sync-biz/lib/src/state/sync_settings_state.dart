import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';

import '../data/sync_local_providers.dart';
import '../domain/sync_settings.dart';

part 'sync_settings_state.g.dart';

@Riverpod(keepAlive: true)
class SyncSettingsNotifier extends _$SyncSettingsNotifier {
  @override
  Future<SyncSettings> build() async {
    final storage = await ref.watch(syncSettingsStorageProvider.future);
    return await storage.load();
  }

  Future<void> save(SyncSettings settings) async {
    SyncSettings old = await future;
    if (settings == old) {
      return;
    }
    final storage = await ref.read(syncSettingsStorageProvider.future);
    await storage.save(settings);
    state = AsyncValue.data(settings);
  }
}

@riverpod
Future<bool> syncEnabled(Ref ref) async {
  // 只有有用户才能同步
  final userId = await ref.watch(currentUserIdentityProvider.future);
  if (userId == null) {
    return false;
  }
  final settings = await ref.watch(syncSettingsProvider.future);
  return settings.enable;
}

@riverpod
Future<bool> realtimeSyncEnabled(Ref ref) async {
  final syncEnable = await ref.watch(syncEnabledProvider.future);
  if (!syncEnable) {
    return false;
  }
  final settings = await ref.watch(syncSettingsProvider.future);
  return settings.enable && settings.realtimeSync;
}
