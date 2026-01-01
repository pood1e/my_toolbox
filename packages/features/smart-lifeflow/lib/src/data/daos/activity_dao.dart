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

  // --- 3. Sync Write (Ack) ---
  Future<void> markSynced(List<String> ids, int newServerTime) async {
    await (update(activities)..where((t) => t.id.isIn(ids))).write(
      ActivitiesCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  // --- 4. Sync Write (Merge) ---
  Future<void> applyRemote(List<ActivityDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final companion = dto.toCompanion(isDirty: false);
        batch.insert(
          activities,
          companion,
          onConflict: DoUpdate((old) => companion),
        );
      }
    });
  }
}
