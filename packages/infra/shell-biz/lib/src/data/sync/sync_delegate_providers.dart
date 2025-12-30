import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../dao_providers.dart';
import 'app_usage_sync_delegate.dart';

part 'sync_delegate_providers.g.dart';

@Riverpod(keepAlive: true)
Future<AppUsageSyncDelegate> appUsageSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  final deviceIdService = await ref.watch(deviceIdServiceProvider.future);

  return AppUsageSyncDelegate(
    daoUse: (action) async {
      final sub = ref.listen(appUsageDaoProvider, (prev, next) {});
      try {
        final dao = await ref.read(appUsageDaoProvider.future);
        await action(dao);
      } finally {
        sub.close();
      }
    },
    dio: dio,
    deviceIdService: deviceIdService,
  );
}
