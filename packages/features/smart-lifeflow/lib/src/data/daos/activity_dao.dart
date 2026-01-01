import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/activity_table.dart';

part 'activity_dao.g.dart';

@DriftAccessor(tables: [Activities])
class ActivityDao extends DatabaseAccessor<LifeflowDatabase>
    with _$ActivityDaoMixin {
  ActivityDao(super.db);

  // --- 1. Local Write ---
  Future<void> save(int nowMs, ActivitiesCompanion item) async {
    await into(activities).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  Future<void> deleteActivity(int nowMs, String id) async {
    await (update(activities)..where((t) => t.id.equals(id))).write(
      ActivitiesCompanion(
        deletedAt: Value(nowMs),
        updatedAt: Value(nowMs),
        isDirty: const Value(true),
      ),
    );
  }

  // --- 2. Sync Read (Push) ---
  Future<List<ActivityEntity>> getDirtyItems() {
    return (select(activities)..where((t) => t.isDirty.equals(true))).get();
  }

  Future<int> getMaxCursor() async {
    final query = select(activities)
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
    for (final entry in ackedItems.entries) {
      final id = entry.key;
      final newServerTime = entry.value;
      final sentTime = snapshots[id];

      if (sentTime == null) continue;

      await customStatement(
        '''
        UPDATE activities
        SET is_dirty = 0, server_updated_at = ?
        WHERE id = ? AND updated_at = ?
        ''',
        [newServerTime, id, sentTime],
      );
    }
  }

  /// 应用远程变更: 过滤回声后 Upsert
  Future<void> applyRemote(List<ActivityDto> remotes) async {
    for (final dto in remotes) {
      final companion = dto.toCompanion(isDirty: false);

      // 1. 回声检查
      final local = await (select(activities)..where((t) => t.id.equals(dto.id))).getSingleOrNull();
      if (local != null && local.serverUpdatedAt >= dto.serverUpdatedAt) {
        continue; // 本地版本更新或相等，跳过
      }

      // 2. 写入覆盖
      await into(activities).insert(
        companion,
        onConflict: DoUpdate((old) => companion),
      );
    }
  }
}
