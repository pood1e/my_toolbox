import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/task_definition_table.dart';

part 'task_definition_dao.g.dart';

@DriftAccessor(tables: [TaskDefinitions])
class TaskDefinitionDao extends DatabaseAccessor<LifeflowDatabase>
    with _$TaskDefinitionDaoMixin {
  TaskDefinitionDao(super.db);

  // 1. 增/改 (自动标记 dirty + 更新本地时间)
  Future<void> save(TaskDefinitionsCompanion entry) async {
    final now = DateTime.now().millisecondsSinceEpoch; // 或使用 TimeProvider
    await into(taskDefinitions).insertOnConflictUpdate(
      entry.copyWith(
        updatedAt: Value(now),
        isDirty: const Value(true), // 👈 标记为脏，等待上传
      ),
    );
  }

  // 2. 获取脏数据 (用于 Push)
  Future<List<TaskDefinitionEntity>> getDirtyItems() {
    return (select(
      taskDefinitions,
    )..where((t) => t.isDirty.equals(true))).get();
  }

  // 3. 获取最大游标 (用于 Pull)
  Future<int> getMaxCursor() async {
    final query = select(taskDefinitions)
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

  Future<void> markSynced(Map<String, int> ackedItems, Map<String, int> snapshots) async {
    // 批量执行，无需再套 transaction (因为外层 Delegate 已经套了)
    // 但为了性能，尽量减少 await 次数，不过对于 customStatement 只能循环调用
    for (final entry in ackedItems.entries) {
      final id = entry.key;
      final newServerTime = entry.value;
      final sentTime = snapshots[id];

      if (sentTime == null) continue; // 理论上不应发生

      // 核心 SQL：
      // 只有当当前的 updatedAt == 发送时的 updatedAt 时，才清除 dirty。
      // 否则说明发送期间用户又改了，保留 dirty=true。
      await customStatement(
        '''
        UPDATE task_definitions
        SET is_dirty = 0, server_updated_at = ?
        WHERE id = ? AND updated_at = ?
        ''',
        [newServerTime, id, sentTime],
      );
    }
  }

  /// 应用远程变更
  Future<void> applyRemote(List<TaskDefinitionDto> remotes) async {
    for (final dto in remotes) {
      final companion = dto.toCompanion(isDirty: false);

      // LWW 检查 (Echo Pruning)
      // 1. 查本地
      final local = await (select(taskDefinitions)..where((t) => t.id.equals(dto.id))).getSingleOrNull();

      // 2. 如果本地版本已经 >= 远程版本，跳过 (回声)
      if (local != null && local.serverUpdatedAt >= dto.serverUpdatedAt) {
        continue;
      }

      // 3. 写入 (Upsert)
      // 使用 batch.insert 或 into().insertOnConflictUpdate 均可
      await into(taskDefinitions).insert(
        companion,
        onConflict: DoUpdate((old) => companion),
      );
    }
  }
}
