import 'package:app_core/di.dart';

import '../data/sync_local_providers.dart';
import '../domain/sync_cursor.dart';
import '../domain/sync_settings.dart';

part 'sync_states.g.dart';

@Riverpod(keepAlive: true)
class SyncingNotifier extends _$SyncingNotifier {
  @override
  Map<String, bool> build() => {};

  void setSyncing(String resourceId, bool syncing) {
    state = {...state, resourceId: syncing};
  }
}

@riverpod
bool resourceSyncing(Ref ref, String resourceId) {
  final syncingMap = ref.read(syncingProvider);
  return syncingMap[resourceId] ?? false;
}

@riverpod
bool anySyncing(Ref ref) {
  final syncingMap = ref.watch(syncingProvider);
  return syncingMap.values.any((syncing) => syncing);
}

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

@Riverpod(keepAlive: true)
class SyncCursorNotifier extends _$SyncCursorNotifier {
  @override
  Future<SyncCursor> build(String resourceId) async {
    final storage = await ref.watch(syncCursorStorageProvider.future);
    return await storage.load(resourceId);
  }

  Future<void> save(SyncCursor cursor) async {
    final old = await future;
    if (cursor == old) {
      return;
    }
    final storage = await ref.read(syncCursorStorageProvider.future);
    await storage.save(resourceId, cursor);
    state = AsyncValue.data(cursor);
  }
}
