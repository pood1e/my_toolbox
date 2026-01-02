import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../lifeflow_database.dart';
import '../local_providers.dart';
import 'lifeflow_sync_delegate.dart';
import 'sync_entity_controller.dart';

part 'sync_delegate_providers.g.dart';

@Riverpod(keepAlive: true)
Future<LifeflowSyncDelegate> lifeflowSyncDelegate(Ref ref) async {
  final dio = await ref.watch(authenticatedDioProvider.future);
  final controllers = <SyncEntityController>[
    // A. Activities
    SyncEntityController(
      daoGetter: (db) => db.activityDao,
      key: 'activities',
      pullSelector: (p) => p.activities,
      gcAction: (db) => db.activityDao.purgeSyncedSoftDeleted(),
      toDto: (e) => e.toDto(),
      toCompanion: (d) => d.toCompanion(),
      toJson: (dto) => dto.toJson(),
      getId: (e) => e.id,
      getCompId: (c) => (c as ActivitiesCompanion).id.value,
      getUpdatedAt: (e) => e.updatedAt,
      getCompServerTime: (c) =>
          (c as ActivitiesCompanion).serverUpdatedAt.value,
    ),

    // B. Logs
    SyncEntityController(
      daoGetter: (db) => db.activityLogDao,
      key: 'activity_logs',
      pullSelector: (p) => p.activityLogs,
      gcAction: (db) => db.activityLogDao.purgeSyncedSoftDeleted(),
      toDto: (e) => e.toDto(),
      toCompanion: (d) => d.toCompanion(),
      toJson: (dto) => dto.toJson(),
      getId: (e) => e.id,
      getCompId: (c) => (c as ActivityLogsCompanion).id.value,
      getUpdatedAt: (e) => e.updatedAt,
      getCompServerTime: (c) =>
          (c as ActivityLogsCompanion).serverUpdatedAt.value,
    ),

    // C. Shortcuts
    SyncEntityController(
      daoGetter: (db) => db.activityShortcutDao,
      key: 'activity_shortcuts',
      pullSelector: (p) => p.activityShortcuts,
      gcAction: null,
      toDto: (e) => e.toDto(),
      toCompanion: (d) => d.toCompanion(),
      toJson: (dto) => dto.toJson(),
      getId: (e) => e.activityId,
      getCompId: (c) => (c as ActivityShortcutsCompanion).activityId.value,
      getUpdatedAt: (e) => e.updatedAt,
      getCompServerTime: (c) =>
          (c as ActivityShortcutsCompanion).serverUpdatedAt.value,
    ),
  ];
  return LifeflowSyncDelegate(
    dbUse: (action) async {
      final sub = ref.listen(lifeflowDatabaseProvider, (prev, next) {});
      try {
        final db = await ref.read(lifeflowDatabaseProvider.future);
        await action(db);
      } finally {
        sub.close();
      }
    },
    dio: dio,
    controllers: controllers,
  );
}
