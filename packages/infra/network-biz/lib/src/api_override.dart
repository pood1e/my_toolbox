import 'package:app_core/di.dart';
import 'package:auth_api/auth_api.dart';
import 'package:network_api/network_api.dart';

import 'data/storage_providers.dart';
import 'service/impl/device_id_service_impl.dart';
import 'service/impl/server_time_service_impl.dart';

class NetworkApiOverride {
  NetworkApiOverride._();

  static Future<ServerTimeService> serverTimeService(Ref ref) async {
    final server = await ref.watch(
      currentUserIdentityProvider.selectAsync((userId) => userId?.server),
    );
    final storage = await ref.watch(serverTimeStorageProvider.future);
    final serviceImpl = ServerTimeServiceImpl(
      storage: storage,
      baseurl: server?.baseUrl,
    );
    await serviceImpl.tryRestoreAnchor();
    return serviceImpl;
  }

  static Future<DeviceIdService> deviceIdService(Ref ref) async {
    final storage = await ref.watch(deviceIdStorageProvider.future);
    return DeviceIdServiceImpl(installIdStorage: storage);
  }
}
