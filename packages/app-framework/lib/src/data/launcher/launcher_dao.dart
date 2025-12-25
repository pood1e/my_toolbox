import 'package:app_core/uuid.dart';
import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../framework_database.dart';
import 'app_usage_entity.dart';

part 'launcher_dao.g.dart';

@DriftAccessor(tables: [AppUsageEntities])
class LauncherDao extends DatabaseAccessor<FrameworkDatabase>
    with _$LauncherDaoMixin {
  LauncherDao(super.db);

  /// 监听所有使用记录 (按最后使用时间倒序)
  Stream<List<AppUsageEntity>> watchAllUsage() {
    return (select(appUsageEntities)..orderBy([
          (t) =>
              OrderingTerm(expression: t.lastUsedAt, mode: OrderingMode.desc),
        ]))
        .watch();
  }

  Future<void> trackUsage(String moduleKey) async {
    final now = DateTime.now();

    // 使用 Drift 的 Upsert 语法
    await into(appUsageEntities).insert(
      AppUsageEntitiesCompanion(
        id: Value(Uuid().v4()),
        module: Value(moduleKey),
        lastUsedAt: Value(now),
        openCount: const Value(1), // 初始值
      ),
      onConflict: DoUpdate(
        (old) => AppUsageEntitiesCompanion.custom(
          lastUsedAt: Constant(now),
          openCount: old.openCount + Constant(1),
          updatedAt: Constant(now),
        ),
        target: [appUsageEntities.module],
      ),
    );
  }

  /// 对应 Load 逻辑: 获取脏数据
  Future<List<AppUsageEntity>> getDirtyEntries(int? cursor) {
    // 这里的 launchEntries 来自 _$LauncherDaoMixin，而不是 db
    return (select(appUsageEntities)..where(
          (t) => t.updatedAt.isBiggerThanValue(
            DateTime.fromMillisecondsSinceEpoch(cursor ?? 0),
          ),
        ))
        .get();
  }

  /// 对应 Merge 逻辑: 批量合并数据
  Future<void> mergeEntries(List<AppUsageEntity> entities) async {
    // DAO 内部可以直接调用 transaction
    await transaction(() async {
      for (final dto in entities) {
        // 假设 mergeCompanion 是 FrameworkDatabase 的扩展方法
        // 在 DAO 中可以通过 `db` 属性访问数据库实例
        await db.mergeCompanion(
          table: appUsageEntities,
          companion: dto.toCompanion(true),
          newId: dto.id,
          // 注意：这里的 t 是 Table 的别名，Drift 会自动处理
          businessKeyFilter: (t) => t.module.equals(dto.module),
        );
      }
    });
  }
}
