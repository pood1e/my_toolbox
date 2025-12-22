import '../domain/sync_settings.dart';

abstract class SyncSettingsStorage {
  Future<SyncSettings> load();

  Future<void> save(SyncSettings settings);
}
