import 'package:data_api/data_api.dart';

import '../../domain/sync_settings.dart';
import '../sync_settings_storage.dart';

class SyncSettingsStorageImpl implements SyncSettingsStorage {
  final KVStore _store;

  SyncSettingsStorageImpl({required KVStore store}) : _store = store;

  @override
  Future<SyncSettings> load() async {
    final enable = await _store.getBool('enable');
    final auto = await _store.getBool('auto');
    final realtime = await _store.getBool('realtime');
    return SyncSettings(
      enable: enable ?? true,
      autoSync: auto ?? true,
      realtimeSync: realtime ?? true,
    );
  }

  @override
  Future<void> save(SyncSettings settings) async {
    await _store.saveBool('enable', settings.enable);
    await _store.saveBool('auto', settings.autoSync);
    await _store.saveBool('realtime', settings.realtimeSync);
  }
}
