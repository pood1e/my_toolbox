import 'package:app_core/di.dart';
import 'package:sync_api/sync_api.dart';
import 'package:sync_biz/sync_biz.dart';

import '../data/dao_providers.dart';
import '../need_override_providers.dart';
import 'impl/launcher_service_impl.dart';
import 'launcher_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(appDefinitionsProvider);
  return LauncherServiceImpl(
    allApps: apps,
    daoGetter: () async {
      return await ref.read(launcherDaoProvider.future);
    },
    syncAction: () async {
      final canSync = await ref.read(autoSyncProvider.future);
      if (!canSync) {
        return;
      }
      final service = await ref.read(syncServiceProvider.future);
      service.sync('launcher');
    },
  );
}
