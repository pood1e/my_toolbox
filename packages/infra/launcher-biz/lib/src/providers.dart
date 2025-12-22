import 'package:auth_biz/auth_biz.dart';
import 'package:core/di.dart';
import 'package:data_biz/data_biz.dart';
import 'package:sync_api/sync_api.dart';

import 'data/launcher_dao.dart';
import 'data/launcher_sync_delegate.dart';
import 'need_override_providers.dart';
import 'service/impl/launcher_service_impl.dart';
import 'service/launcher_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<LauncherDao> launcherDao(Ref ref) async {
  final db = await ref.watch(currentUserDatabaseProvider.future);
  return LauncherDao(db);
}

@riverpod
Future<LauncherSyncDelegate> launcherSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  return LauncherSyncDelegate(
    dio: dio,
    daoGetter: () async {
      return await ref.read(launcherDaoProvider.future);
    },
  );
}

@Riverpod(keepAlive: true)
Future<LauncherService> launcherService(Ref ref) async {
  final apps = ref.read(appDefinitionsProvider);
  return LauncherServiceImpl(
    allApps: apps,
    daoGetter: () async {
      return await ref.read(launcherDaoProvider.future);
    },
    syncAction: () async {
      final service = await ref.read(syncServiceProvider.future);
      service.sync('launcher');
    },
  );
}
