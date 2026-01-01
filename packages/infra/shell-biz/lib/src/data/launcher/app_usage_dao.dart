import 'package:app_core/logger.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../shell_database.dart';
import '../sync/sync_sequence_table.dart';
import 'app_usage_dto.dart';
import 'app_usage_entity.dart';

part 'app_usage_dao.g.dart';

@DriftAccessor(tables: [AppUsageEntities, SyncSequenceTable])
class AppUsageDao extends DatabaseAccessor<ShellDatabase>
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

  // ===========================================================================
  // 1. 本地业务逻辑 (Local Write)
  // ===========================================================================

  /// 记录一次打开/使用
  /// [nowMs]: 校准后的当前时间戳
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
  // 2. 同步：准备发送 (Push Prep - Locking)
  // ===========================================================================

  Future<SyncDelta<AppUsageDelta>?> lockAndGetPayload(String deviceId) async {
    return await transaction(() async {
      // A. 获取或初始化元数据 (只关心 Sequence)
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

      // B. 检查状态：是重试还是新批次？
      // 判断依据：是否有 locked > 0 的数据
      final hasPendingLock =
          await (select(appUsageEntities)
                ..where((t) => t.lockedCount.isBiggerThanValue(0)))
              .get()
              .then((l) => l.isNotEmpty);

      if (hasPendingLock) {
        // [重试] 保持 Sequence 不变，直接重发 locked 数据
        logger.i('♻️ [Sync] 检测到锁定数据，重试 Sequence: $currentSequence');
      } else {
        // [新批次] 检查是否有新数据
        final hasNewData =
            await (select(appUsageEntities)
                  ..where((t) => t.unsyncCount.isBiggerThanValue(0)))
                .get()
                .then((l) => l.isNotEmpty);

        if (!hasNewData) return null; // 无数据，不发

        // 状态跃迁
        currentSequence += 1;

        // 1. 更新 Sequence
        await update(
          syncSequenceTable,
        ).replace(meta.copyWith(sequence: currentSequence));

        // 2. 搬运数据: unsync -> locked
        await customStatement(
          'UPDATE app_usage_entities '
          'SET locked_count = locked_count + unsync_count, '
          '    unsync_count = 0 '
          'WHERE unsync_count > 0',
        );
      }

      // C. 构建 DTO
      final dirtyItems = await (select(
        appUsageEntities,
      )..where((t) => t.lockedCount.isBiggerThanValue(0))).get();

      return SyncDelta<AppUsageDelta>(
        sequence: currentSequence, // 核心字段
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

  // ===========================================================================
  // 3. 同步：发送成功清理 (Push Commit)
  // ===========================================================================

  Future<void> onSuccess() async {
    // 收到 Ack，说明 lockedCount 已经成功累加到服务端了，本地可以清零
    await customStatement(
      'UPDATE app_usage_entities SET locked_count = 0 WHERE locked_count > 0',
    );
  }

  // ===========================================================================
  // 4. 同步：获取游标 (Pull Prep)
  // ===========================================================================

  /// 动态计算游标：MAX(server_updated_at)
  Future<int> getMaxCursor() async {
    final query = select(appUsageEntities)
      ..orderBy([
        (t) => OrderingTerm(
          expression: t.serverUpdatedAt,
          mode: OrderingMode.desc,
        ),
      ])
      ..limit(1);

    final result = await query.getSingleOrNull();
    return result?.serverUpdatedAt ?? 0;
  }

  // ===========================================================================
  // 5. 同步：应用远程数据 (Merge / Echo)
  // ===========================================================================

  Future<void> applyRemoteStats(List<AppUsagePatch> remotes) async {
    await transaction(() async {
      for (final remote in remotes) {
        // 1. 过滤回声 (Echo Pruning)
        // 先查本地版本，如果本地已经比远程新（或相等），则跳过写入，节省 IO
        final local = await (select(
          appUsageEntities,
        )..where((t) => t.module.equals(remote.module))).getSingleOrNull();

        if (local != null && local.serverUpdatedAt >= remote.serverUpdatedAt) {
          continue;
        }

        // 2. 执行 Upsert
        // 公式：Total = ServerTotal + LocalUnsync
        await into(appUsageEntities).insert(
          AppUsageEntitiesCompanion(
            module: Value(remote.module),
            openCount: Value(remote.totalCount),
            // 基数
            lastUsedAt: Value(remote.lastUsedAt),
            // 业务时间
            serverUpdatedAt: Value(remote.serverUpdatedAt),
            // ✅ 锚点更新
            unsyncCount: const Value(0),
            // Insert时默认0
            lockedCount: const Value(0),
          ),
          onConflict: DoUpdate(
            (old) => AppUsageEntitiesCompanion.custom(
              // 更新基数，保留本地未同步的增量
              openCount: Constant(remote.totalCount) + old.unsyncCount,
              // 时间取最大值
              lastUsedAt: CustomExpression<int>(
                'MAX(last_used_at, ${remote.lastUsedAt})',
              ),
              // 更新锚点
              serverUpdatedAt: Constant(remote.serverUpdatedAt),
            ),
          ),
        );
      }
    });
  }

  Future<bool> checkHasChanges() async {
    return await (select(appUsageEntities)
      ..where((t) => t.unsyncCount.isBiggerThanValue(0)))
        .get()
        .then((l) => l.isNotEmpty);
  }
}
