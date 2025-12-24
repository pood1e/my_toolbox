import 'package:app_core/di.dart';
import 'package:sync_api/sync_api.dart';

import '../data/dao_providers.dart';
import '../feature_registry.dart';
import 'impl/launcher_service_impl.dart';
import 'launcher_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(featureRegistryProvider).appDefinitions;
  return LauncherServiceImpl(
    allApps: apps,
    dao: await ref.watch(launcherDaoProvider.future),
    syncAction: () async {
      final autoSyncChecker = ref.read(autoSyncProvider);
      if (!(await autoSyncChecker())) {
        return;
      }
      final action = ref.read(syncActionProvider);
      // 不等待
      action('launcher');
    },
  );
}
