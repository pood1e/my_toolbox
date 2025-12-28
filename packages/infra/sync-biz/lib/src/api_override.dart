import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:sync_api/sync_api.dart';

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

  static SyncAction syncAction(Ref ref) {
    return (resourceId) async {
      final syncEnable = await ref.read(syncEnabledProvider.future);
      if (!syncEnable) {
        return false;
      }
      try {
        final syncService = await ref.read(syncServiceProvider.future);
        await syncService.sync(resourceId);
        return true;
      } catch (e, stack) {
        logger.e('auto sync failed: $e', error: e, stackTrace: stack);
        return false;
      }
    };
  }
}
