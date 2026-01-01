import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/schedule_item_table.dart';

part 'schedule_item_dao.g.dart';

@DriftAccessor(tables: [ScheduleItems])
class ScheduleItemDao extends DatabaseAccessor<LifeflowDatabase>
    with _$ScheduleItemDaoMixin {
  ScheduleItemDao(super.attachedDatabase);

  // --- Local ---
  Future<void> save(ScheduleItemsCompanion item, int nowMs) async {
    await into(scheduleItems).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  Future<void> deleteItem(String id, int nowMs) async {
    await (update(scheduleItems)..where((t) => t.id.equals(id))).write(
      ScheduleItemsCompanion(
        deletedAt: Value(nowMs),
        updatedAt: Value(nowMs),
        isDirty: const Value(true),
      ),
    );
  }

  // --- Sync (保持不变) ---
  Future<List<ScheduleItemEntity>> getDirtyItems() =>
      (select(scheduleItems)..where((t) => t.isDirty.equals(true))).get();

  Future<int> getMaxCursor() async {
    final res =
        await (select(scheduleItems)
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
      final id = entry.key;
      final newServerTime = entry.value;
      final sentTime = snapshots[id];

      if (sentTime == null) continue;

      await customStatement(
        '''
        UPDATE schedule_items
        SET is_dirty = 0, server_updated_at = ?
        WHERE id = ? AND updated_at = ?
        ''',
        [newServerTime, id, sentTime],
      );
    }
  }

  Future<void> applyRemote(List<ScheduleItemDto> remotes) async {
    for (final dto in remotes) {
      final companion = dto.toCompanion(isDirty: false);

      final local = await (select(scheduleItems)..where((t) => t.id.equals(dto.id))).getSingleOrNull();
      if (local != null && local.serverUpdatedAt >= dto.serverUpdatedAt) {
        continue;
      }

      await into(scheduleItems).insert(
        companion,
        onConflict: DoUpdate((old) => companion),
      );
    }
  }
}
