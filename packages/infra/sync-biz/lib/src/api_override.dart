import 'package:app_core/di.dart';
import 'package:sync_api/sync_api.dart';

import 'service/impl/auto_sync_service_impl.dart';
import 'service/service_providers.dart';
import 'state/sync_settings_state.dart';

class SyncApiOverride {
  SyncApiOverride._();

  static Future<bool> autoSyncEnalbed(Ref ref) async {
    final syncEnable = await ref.watch(syncEnabledProvider.future);
    if (!syncEnable) {
      return false;
    }
    final settings = await ref.watch(syncSettingsProvider.future);
    return settings.enable && settings.autoSync;
  }

  static Future<SyncService> syncService(Ref ref) async {
    return await ref.watch(syncServiceImplProvider.future);
  }

  static Future<AutoSyncService> autoSyncService(Ref ref) async {
    final service = await ref.watch(syncServiceProvider.future);
    return AutoSyncServiceImpl(service);
  }
}
