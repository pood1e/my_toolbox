import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:auth_api/auth_api.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:sync_api/sync_api.dart';

import 'api/sync_standard_api_impl.dart';
import 'service/service_providers.dart';
import 'state/sync_states.dart';

class SyncApiOverride {
  SyncApiOverride._();

  static SyncAction syncAction(Ref ref) {
    return (resourceId) async {
      final syncService = await ref.read(syncServiceProvider.future);
      await syncService.sync(resourceId);
    };
  }

  static Future<SyncStandardApi<T>> syncStandardApi<T>(
    Ref ref,
    (String, FromJson<T>, ToJson<T>) arg,
  ) async {
    final dio = await ref.read(authenticatedDioProvider.future);
    return SyncStandardApiImpl<T>(
      dio: dio,
      apiPath: arg.$1,
      fromJson: arg.$2,
      toJson: arg.$3,
    );
  }

  static Future<bool> Function() autoSync(Ref ref) {
    return () async {
      final settings = await ref.watch(syncSettingsProvider.future);
      if (!settings.enable || !settings.autoSync) {
        return false;
      }
      // 在网络不可用和token有效时进行尝试
      final ConnectionAvailability availability = ref.watch(
        connectionAvailabiltyProvider,
      );
      return availability == ConnectionAvailability.active ||
          availability == ConnectionAvailability.offline;
    };
  }
}
