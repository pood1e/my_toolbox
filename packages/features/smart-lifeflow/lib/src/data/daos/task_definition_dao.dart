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

  // 4. 处理远程数据 (Pull/Merge)
  Future<void> applyRemote(List<TaskDefinitionDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final companion = dto.toCompanion(isDirty: false);

        batch.insert(
          taskDefinitions,
          companion,
          // 这行代码实现了 insertOnConflictUpdate 的逻辑：
          // 如果冲突，则用新数据(companion)更新旧数据
          onConflict: DoUpdate((old) => companion),
        );
      }
    });
  }

  // 5. 处理 Ack (清除脏标记)
  Future<void> markSynced(List<String> ids, int newServerTime) async {
    await (update(taskDefinitions)..where((t) => t.id.isIn(ids))).write(
      TaskDefinitionsCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }
}
