import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/daily_snapshot_table.dart';

part 'daily_snapshot_dao.g.dart';

@DriftAccessor(tables: [DailySnapshots])
class DailySnapshotDao extends DatabaseAccessor<LifeflowDatabase>
    with _$DailySnapshotDaoMixin {
  DailySnapshotDao(super.attachedDatabase);

  // --- Local ---
  Future<void> save(DailySnapshotsCompanion item, int nowMs) async {
    await into(dailySnapshots).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  // --- Sync (保持不变) ---
  Future<List<DailySnapshotEntity>> getDirtyItems() =>
      (select(dailySnapshots)..where((t) => t.isDirty.equals(true))).get();

  Future<int> getMaxCursor() async {
    final res =
        await (select(dailySnapshots)
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
    await (update(dailySnapshots)..where((t) => t.id.isIn(ids))).write(
      DailySnapshotsCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  Future<void> applyRemote(List<DailySnapshotDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final cmp = dto.toCompanion(isDirty: false);
        batch.insert(dailySnapshots, cmp, onConflict: DoUpdate((_) => cmp));
      }
    });
  }
}
