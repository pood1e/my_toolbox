import 'package:app_core/di.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../data/dao_providers.dart';
import 'impl/launcher_service_impl.dart';
import 'launcher_service.dart';

part 'service_providers.g.dart';

@riverpod
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(featureRegistryProvider).appDefinitions;
  final timeService = await ref.watch(serverTimeServiceProvider.future);
  // side effect
  ref.watch(appUsageChangesListenerProvider);
  return LauncherServiceImpl(
    allApps: apps,
    dao: await ref.watch(appUsageDaoProvider.future),
    serverTimeService: timeService,
  );
}

@riverpod
Future<void> appUsageChangesListener(Ref ref) async {
  final db = await ref.watch(shellDatabaseProvider.future);

  final sub = db
      .tableUpdates(TableUpdateQuery.onTable(db.appUsageEntities))
      .listen((updates) async {
        if (await ref.read(autoSyncEnabledProvider.future)) {
          final autoSyncService = await ref.watch(
            autoSyncServiceProvider.future,
          );
          autoSyncService.markSync('app_usage', debounce: Duration.zero);
        }
      });

  ref.onDispose(() {
    sub.cancel();
  });
}
