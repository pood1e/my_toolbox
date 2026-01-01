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

  Future<void> markSynced(List<String> ids, int newServerTime) async {
    await (update(scheduleItems)..where((t) => t.id.isIn(ids))).write(
      ScheduleItemsCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  Future<void> applyRemote(List<ScheduleItemDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final cmp = dto.toCompanion(isDirty: false);
        batch.insert(scheduleItems, cmp, onConflict: DoUpdate((_) => cmp));
      }
    });
  }
}
