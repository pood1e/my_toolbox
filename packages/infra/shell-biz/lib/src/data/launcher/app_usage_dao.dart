import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../shell_database.dart';
import '../sync/sync_sequence_table.dart';
import 'app_usage_dto.dart';
import 'app_usage_entity.dart';

part 'app_usage_dao.g.dart';

@DriftAccessor(tables: [AppUsageEntities, SyncSequenceTable])
class AppUsageDao
    extends
        StandardDeltaDao<
          ShellDatabase,
          AppUsageEntities,
          AppUsageEntity,
          SyncSequenceTable,
          SyncSequence
        >
    with _$AppUsageDaoMixin {
  AppUsageDao(super.attachedDatabase);

  @override
  String get syncModuleId => 'app_usage';

  @override
  TableInfo<SyncSequenceTable, SyncSequence> get sequenceTable =>
      syncSequenceTable;

  Stream<List<AppUsageEntity>> watchAllUsage() {
    return (select(appUsageEntities)..orderBy([
          (t) =>
              OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  // ===========================================================================
  // 1. 本地业务写入 (Local Write)
  // ===========================================================================

  /// 记录一次使用
  Future<void> recordUsage(String moduleName, int nowMs) async {
    await transaction(() async {
      await into(appUsageEntities).insert(
        AppUsageEntitiesCompanion(
          module: Value(moduleName),
          lastUsedAt: Value(nowMs),
          openCount: const Value(1),
          unsyncCount: const Value(1),
          lockedCount: const Value(0),
          serverUpdatedAt: const Value(0), // 新数据默认 0
        ),
        onConflict: DoUpdate(
          (old) => AppUsageEntitiesCompanion.custom(
            // UI总数 + 1
            openCount: old.openCount + const Constant(1),
            // 未同步增量 + 1
            unsyncCount: old.unsyncCount + const Constant(1),
            // LWW 时间更新
            lastUsedAt: Constant(nowMs),
          ),
        ),
      );
    });
  }

  // ===========================================================================
  // 2. 实现 DeltaOpInterface (框架要求的流程逻辑)
  // ===========================================================================

  @override
  Future<DeltaStateSnapshot> checkState() async {
    // 检查是否有需要同步的数据
    final hasUnsync =
        await (select(appUsageEntities)
              ..where((t) => t.unsyncCount.isBiggerThanValue(0)))
            .get()
            .then((v) => v.isNotEmpty);

    final hasLocked =
        await (select(appUsageEntities)
              ..where((t) => t.lockedCount.isBiggerThanValue(0)))
            .get()
            .then((v) => v.isNotEmpty);

    return DeltaStateSnapshot(hasUnsync: hasUnsync, hasLocked: hasLocked);
  }

  @override
  Future<void> moveUnsyncToLocked() async {
    // 核心流转: unsync 转移到 locked
    await customStatement(
      'UPDATE app_usage_entities '
      'SET locked_count = locked_count + unsync_count, '
      '    unsync_count = 0 '
      'WHERE unsync_count > 0',
    );
  }

  @override
  Future<void> clearLocked() async {
    // Commit: 清空 locked
    await customStatement(
      'UPDATE app_usage_entities SET locked_count = 0 WHERE locked_count > 0',
    );
  }

  @override
  Future<List<AppUsageEntity>> getLockedItems() {
    return (select(
      appUsageEntities,
    )..where((t) => t.lockedCount.isBiggerThanValue(0))).get();
  }

  // ===========================================================================
  // 3. 处理下行合并 (Merge Logic)
  // ===========================================================================

  /// 应用远程补丁
  Future<void> applyPatches(List<AppUsagePatch> patches) async {
    await batch((batch) async {
      for (final remote in patches) {
        // Echo Pruning: 如果本地锚点已经比远程新(或相等)，跳过
        // 注意: 这里为了性能，建议先在内存过滤，或者直接 Upsert 覆盖

        // 逻辑: 更新 server_count 和 server_updated_at，取 MAX(lastUsedAt)
        // 注意: unsync_count 和 locked_count 保持不变！

        batch.insert(
          appUsageEntities,
          AppUsageEntitiesCompanion(
            module: Value(remote.module),
            openCount: Value(remote.totalCount),
            serverUpdatedAt: Value(remote.serverUpdatedAt),
            lastUsedAt: Value(remote.lastUsedAt),
            unsyncCount: const Value(0),
            lockedCount: const Value(0),
          ),
          onConflict: DoUpdate(
            (old) => AppUsageEntitiesCompanion.custom(
              // 更新基准值
              openCount: Constant(remote.totalCount),
              // 更新锚点
              serverUpdatedAt: Constant(remote.serverUpdatedAt),
              // 时间取最大值
              lastUsedAt: CustomExpression<int>(
                'MAX(last_used_at, ${remote.lastUsedAt})',
              ),
              // unsync 和 locked 保持原样，不要覆盖！
            ),
          ),
        );
      }
    });
  }

  @override
  TableInfo<AppUsageEntities, AppUsageEntity> get table => appUsageEntities;
}
