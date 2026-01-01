import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/activity_log_table.dart';

part 'activity_log_dao.g.dart';

@DriftAccessor(tables: [ActivityLogs])
class ActivityLogDao extends DatabaseAccessor<LifeflowDatabase>
    with _$ActivityLogDaoMixin {
  ActivityLogDao(super.attachedDatabase);

  // --- Local ---
  Future<void> save(ActivityLogsCompanion item, int nowMs) async {
    // Log 通常是追加的，但支持修改备注
    await into(activityLogs).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  Future<void> deleteLog(String id, int nowMs) async {
    await (update(activityLogs)..where((t) => t.id.equals(id))).write(
      ActivityLogsCompanion(
        deletedAt: Value(nowMs),
        updatedAt: Value(nowMs),
        isDirty: const Value(true),
      ),
    );
  }

  // --- Sync (保持不变) ---
  Future<List<ActivityLogEntity>> getDirtyItems() =>
      (select(activityLogs)..where((t) => t.isDirty.equals(true))).get();

  Future<int> getMaxCursor() async {
    final res =
        await (select(activityLogs)
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

  Future<void> markSynced(List<String> ids, int newServerTime) async {
    await (update(activityLogs)..where((t) => t.id.isIn(ids))).write(
      ActivityLogsCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  Future<void> applyRemote(List<ActivityLogDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final cmp = dto.toCompanion(isDirty: false);
        batch.insert(activityLogs, cmp, onConflict: DoUpdate((_) => cmp));
      }
    });
  }
}
