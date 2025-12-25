import 'package:app_core/di.dart';
import 'package:app_core/stream.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'framework_database.dart';
import 'launcher/launcher_dao.dart';

part 'dao_providers.g.dart';

@riverpod
Future<FrameworkDatabase> frameworkDatabase(Ref ref) async {
  final db = await ref.watch(
    userDbStoreProvider(
      DatabaseId('framework', (e) => FrameworkDatabase(e)),
    ).future,
  );

  final autoSyncEnabled = await ref.watch(autoSyncEnabledProvider.future);
  if (autoSyncEnabled) {
    final launcherSub = db
        .tableUpdates(TableUpdateQuery.onTable(db.appUsageEntities))
        .debounce(Duration(seconds: 5))
        .listen((updates) async {
          final action = ref.read(syncActionProvider);
          await action('launcher');
        });

    ref.onDispose(() => launcherSub.cancel());
  }

  return db;
}

@riverpod
Future<LauncherDao> launcherDao(Ref ref) async {
  final db = await ref.watch(frameworkDatabaseProvider.future);
  return LauncherDao(db);
}
