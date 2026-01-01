import 'package:drift/drift.dart';

import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';
import '../mapper/sync_mappers.dart';
import '../tables/plan_table.dart';

part 'plan_dao.g.dart';

@DriftAccessor(tables: [Plans])
class PlanDao extends DatabaseAccessor<LifeflowDatabase> with _$PlanDaoMixin {
  PlanDao(super.attachedDatabase);

  // --- Local ---
  Future<void> save(PlansCompanion item, int nowMs) async {
    await into(plans).insert(
      item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      onConflict: DoUpdate(
        (old) =>
            item.copyWith(updatedAt: Value(nowMs), isDirty: const Value(true)),
      ),
    );
  }

  Future<void> deletePlan(String id, int nowMs) async {
    await (update(plans)..where((t) => t.id.equals(id))).write(
      PlansCompanion(
        deletedAt: Value(nowMs),
        updatedAt: Value(nowMs),
        isDirty: const Value(true),
      ),
    );
  }

  // --- Sync (保持不变) ---
  Future<List<PlanEntity>> getDirtyItems() =>
      (select(plans)..where((t) => t.isDirty.equals(true))).get();

  Future<int> getMaxCursor() async {
    final res =
        await (select(plans)
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
    await (update(plans)..where((t) => t.id.isIn(ids))).write(
      PlansCompanion(
        isDirty: const Value(false),
        serverUpdatedAt: Value(newServerTime),
      ),
    );
  }

  Future<void> applyRemote(List<PlanDto> remotes) async {
    await batch((batch) {
      for (final dto in remotes) {
        final cmp = dto.toCompanion(isDirty: false);
        batch.insert(plans, cmp, onConflict: DoUpdate((_) => cmp));
      }
    });
  }
}
