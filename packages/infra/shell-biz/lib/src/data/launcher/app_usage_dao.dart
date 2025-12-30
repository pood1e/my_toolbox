import 'package:app_core/logger.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../framework_database.dart';
import '../sync/sync_sequence_table.dart';
import 'app_usage_dto.dart';
import 'app_usage_entity.dart';

part 'app_usage_dao.g.dart';

@DriftAccessor(tables: [AppUsageEntities, SyncSequenceTable])
class AppUsageDao extends DatabaseAccessor<FrameworkDatabase>
    with _$AppUsageDaoMixin {
  static const String _kModuleId = 'app_usage';

  AppUsageDao(super.attachedDatabase);

  Stream<List<AppUsage>> watchAllUsage() {
    return (select(appUsageEntities)..orderBy([
          (t) =>
              OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<void> recordUsage(String moduleName, int now) async {
    await transaction(() async {
      await into(appUsageEntities).insert(
        AppUsageEntitiesCompanion(
          module: Value(moduleName),
          lastUsedAt: Value(now),
          openCount: const Value(1),
          unsyncCount: const Value(1),
          lockedCount: const Value(0),
        ),
        onConflict: DoUpdate(
          (old) => AppUsageEntitiesCompanion.custom(
            openCount: old.openCount + const Constant(1),
            unsyncCount: old.unsyncCount + const Constant(1),
            lastUsedAt: Constant(now),
          ),
        ),
      );
    });
  }

  Future<bool> checkHasChanges() async {
    return await (select(appUsageEntities)
          ..where((t) => t.unsyncCount.isBiggerThanValue(0)))
        .get()
        .then((l) => l.isNotEmpty);
  }

  Future<SyncDelta<AppUsageDelta>?> lockAndGetPayload(
    String deviceId,
  ) async {
    return await transaction(() async {
      // 1. 初始化或获取 Meta
      var meta = await (select(
        syncSequenceTable,
      )..where((t) => t.moduleId.equals(_kModuleId))).getSingleOrNull();
      if (meta == null) {
        await into(
          syncSequenceTable,
        ).insert(SyncSequence(moduleId: _kModuleId, sequence: 0));
        meta = await (select(
          syncSequenceTable,
        )..where((t) => t.moduleId.equals(_kModuleId))).getSingle();
      }
      int currentSequence = meta.sequence;

      // 2. 【核心判断】检查是否处于 "Pending/Retry" 状态
      // 只要有一行数据的 lockedCount > 0，就说明上次没发完
      final hasPendingLock =
          await (select(appUsageEntities)
                ..where((t) => t.lockedCount.isBiggerThanValue(0)))
              .get()
              .then((l) => l.isNotEmpty);

      if (hasPendingLock) {
        logger.i('♻️ 检测到锁定数据，重试 Sequence: $currentSequence');
      } else {
        final hasNewData = await checkHasChanges();
        if (!hasNewData) return null; // 啥都没有，不发

        // 状态跃迁：Sequence + 1
        currentSequence += 1;

        await update(
          syncSequenceTable,
        ).replace(meta.copyWith(sequence: currentSequence));

        await customStatement(
          'UPDATE app_usage_entities '
          'SET locked_count = locked_count + unsync_count, '
          '    unsync_count = 0 '
          'WHERE unsync_count > 0',
        );
      }

      final dirtyItems = await (select(
        appUsageEntities,
      )..where((t) => t.lockedCount.isBiggerThanValue(0))).get();

      return SyncDelta<AppUsageDelta>(
        sequence: currentSequence,
        deviceId: deviceId,
        deltas: dirtyItems
            .map(
              (e) => AppUsageDelta(
                module: e.module,
                deltaCount: e.lockedCount,
                lastUsedAt: e.lastUsedAt,
              ),
            )
            .toList(),
      );
    });
  }

  Future<void> onSuccess() async {
    await transaction(() async {
      await customStatement(
        'UPDATE app_usage_entities SET locked_count = 0 WHERE locked_count > 0',
      );
    });
  }

  Future<void> applyRemoteStats(List<AppUsagePatch> remotes) async {
    await transaction(() async {
      for (final remote in remotes) {
        final remoteTimeMs = remote.lastUsedAt;
        await customStatement(
          '''
          INSERT INTO app_usage_entities 
            (module, open_count, last_used_at, unsync_count, locked_count)
          VALUES 
            (?1, ?2, ?3, 0, 0)
          ON CONFLICT(module) DO UPDATE SET
            open_count = ?2 + unsync_count,
            last_used_at = MAX(last_used_at, ?3)
          ''',
          [
            remote.module, // ?1
            remote.totalCount, // ?2
            remoteTimeMs, // ?3
          ],
        );
      }
    });
  }
}
