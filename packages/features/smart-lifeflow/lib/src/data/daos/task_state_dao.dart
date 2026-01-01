import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/task_state_table.dart';

part 'task_state_dao.g.dart';

@DriftAccessor(tables: [TaskStates])
class TaskStateDao extends DatabaseAccessor<LifeflowDatabase>
    with _$TaskStateDaoMixin {
  TaskStateDao(super.attachedDatabase);

  // --- Local ---
  // 通常由打卡逻辑调用
  Future<void> updateState(TaskStatesCompanion item, int nowMs) async {
    await into(taskStates).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  // --- Sync (保持不变) ---
  Future<List<TaskStateEntity>> getDirtyItems() =>
      (select(taskStates)..where((t) => t.isDirty.equals(true))).get();

  Future<int> getMaxCursor() async {
    final res =
        await (select(taskStates)
              ..orderBy([
                (t) => OrderingTerm(
                  expression: t.serverUpdatedAt,
                  mode: OrderingMode.desc,
                ),
              ])
              ..limit(1))
            .getSingleOrNull();
    return res?.serverUpdatedAt ?? 0;
  }

  Future<void> markSynced(Map<String, int> ackedItems, Map<String, int> snapshots) async {
    for (final entry in ackedItems.entries) {
      final id = entry.key; // 这里是 taskId
      final newServerTime = entry.value;
      final sentTime = snapshots[id];

      if (sentTime == null) continue;

      // 注意 WHERE 条件是 task_id
      await customStatement(
        '''
        UPDATE task_states
        SET is_dirty = 0, server_updated_at = ?
        WHERE task_id = ? AND updated_at = ?
        ''',
        [newServerTime, id, sentTime],
      );
    }
  }

  Future<void> applyRemote(List<TaskStateDto> remotes) async {
    for (final dto in remotes) {
      final companion = dto.toCompanion(isDirty: false);

      // LWW Check
      final local = await (select(taskStates)..where((t) => t.taskId.equals(dto.id))).getSingleOrNull();
      if (local != null && local.serverUpdatedAt >= dto.serverUpdatedAt) {
        continue;
      }

      await into(taskStates).insert(
        companion,
        onConflict: DoUpdate((old) => companion),
      );
    }
  }
}
