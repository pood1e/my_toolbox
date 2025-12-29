import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../data/dao_providers.dart';
import '../feature_registry.dart';
import 'impl/launcher_service_impl.dart';
import 'launcher_service.dart';

part 'service_providers.g.dart';

@riverpod
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(featureRegistryProvider).appDefinitions;
  final timeService = await ref.watch(serverTimeServiceProvider.future);
  final syncAction = ref.read(syncActionProvider);
  return LauncherServiceImpl(
    syncAction: syncAction,
    allApps: apps,
    dao: await ref.watch(appUsageDaoProvider.future),
    serverTimeService: timeService,
  );
}
