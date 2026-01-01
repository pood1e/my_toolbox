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

  Future<void> markSynced(List<String> taskIds, int newServerTime) async {
    await (update(taskStates)..where((t) => t.taskId.isIn(taskIds))).write(
      TaskStatesCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  Future<void> applyRemote(List<TaskStateDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final cmp = dto.toCompanion(isDirty: false);
        batch.insert(taskStates, cmp, onConflict: DoUpdate((_) => cmp));
      }
    });
  }
}
