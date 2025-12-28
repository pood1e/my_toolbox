import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../dao_providers.dart';
import 'app_usage_sync_delegate.dart';

part 'sync_delegate_providers.g.dart';

@riverpod
Future<AppUsageSyncDelegate> appUsageSyncDelegate(Ref ref) async {
  final dao = await ref.watch(appUsageDaoProvider.future);
  final dio = await ref.watch(authenticatedDioProvider.future);
  final timeService = await ref.watch(serverTimeServiceProvider.future);
  final deviceIdService = await ref.watch(deviceIdServiceProvider.future);
  return AppUsageSyncDelegate(
    dao: dao,
    dio: dio,
    serverTimeService: timeService,
    deviceIdService: deviceIdService,
  );
}
