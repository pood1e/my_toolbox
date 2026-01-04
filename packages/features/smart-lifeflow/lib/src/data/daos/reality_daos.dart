import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import '../lifeflow_database.dart';
import '../tables/reality_tables.dart';

part 'reality_daos.g.dart';

@DriftAccessor(tables: [Activities])
class ActivityDao extends DatabaseAccessor<LifeflowDatabase>
    with
        _$ActivityDaoMixin,
        GenericLwwSyncDaoMixin<LifeflowDatabase, Activities, ActivityEntity>,
        StandardLwwSyncDaoMixin<LifeflowDatabase, Activities, ActivityEntity> {
  ActivityDao(super.db);

  @override
  TableInfo get table => activities;

  // ===========================================================================
  // 业务查询
  // ===========================================================================

  /// 监听所有活跃活动 (未删除)
  /// [includeArchived]: 是否包含已归档的
  Stream<List<ActivityEntity>> watchAll({bool includeArchived = false}) {
    final query = select(activities);

    // 1. 过滤软删除 (Standard Mixin 保证了 deletedAt 字段存在)
    query.where((t) => t.deletedAt.isNull());

    // 2. 排序: 默认按名称或创建时间
    // 这里简单按创建时间倒序
    query.orderBy([
      (t) => OrderingTerm(expression: t.createdAt, mode: OrderingMode.desc),
    ]);

    return query.watch();
  }

  /// 获取单个活动 (用于验证或详情)
  Future<ActivityEntity?> getById(String id) {
    return (select(activities)
          ..where((t) => t.id.equals(id))
          ..where((t) => t.deletedAt.isNull()))
        .getSingleOrNull();
  }
}

@DriftAccessor(tables: [ActivityLogs])
class ActivityLogDao extends DatabaseAccessor<LifeflowDatabase>
    with
        _$ActivityLogDaoMixin,
    // 1. 基础同步能力
        GenericLwwSyncDaoMixin<LifeflowDatabase, ActivityLogs, ActivityLogEntity>,
    // 2. 标准表能力 (自动处理 id, deletedAt)
        StandardLwwSyncDaoMixin<LifeflowDatabase, ActivityLogs, ActivityLogEntity> {

  ActivityLogDao(super.db);

  @override
  TableInfo get table => activityLogs;

  // ===========================================================================
  // 业务查询
  // ===========================================================================

  /// 监听指定时间范围内的日志
  /// [startMs] & [endMs]: 物理时间范围 (UTC)
  Stream<List<ActivityLogEntity>> watchLogsInRange(int startMs, int endMs) {
    final query = select(activityLogs);

    // 1. 时间范围过滤: Log 的开始时间落在区间内
    query.where((t) => t.startTime.isBetweenValues(startMs, endMs));

    // 2. 过滤软删除
    query.where((t) => t.deletedAt.isNull());

    // 3. 排序: 开始时间倒序
    query.orderBy([
          (t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)
    ]);

    return query.watch();
  }

  /// 获取全库最新的一条活跃记录
  /// (用于 PlanningService 判断用户是否刚睡醒)
  Future<ActivityLogEntity?> getLastLogAny() {
    return (select(activityLogs)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm(expression: t.startTime, mode: OrderingMode.desc)])
      ..limit(1)
    ).getSingleOrNull();
  }
}


@DriftAccessor(tables: [ActivityShortcuts, Activities])
class ActivityShortcutDao extends DatabaseAccessor<LifeflowDatabase>
    with
        _$ActivityShortcutDaoMixin,
    // 只使用通用 Mixin，因为主键不是 standard id
        GenericLwwSyncDaoMixin<LifeflowDatabase, ActivityShortcuts, ActivityShortcutEntity> {

  ActivityShortcutDao(super.db);

  @override
  TableInfo get table => activityShortcuts;

  // 🎯 核心映射: 告诉 Mixin 主键是 activityId
  @override
  Expression<bool> whereId(ActivityShortcuts t, String id) => t.activityId.equals(id);

  // ===========================================================================
  // 手动补全软删除 (因为没有混入 StandardMixin)
  // ===========================================================================

  Future<void> deleteLocal(String activityId, int nowMs) async {
    final query = update(activityShortcuts)..where((t) => t.activityId.equals(activityId));

    await query.write(RawValuesInsertable({
      activityShortcuts.deletedAt.name: Constant(nowMs),
      activityShortcuts.updatedAt.name: Constant(nowMs),
      activityShortcuts.isDirty.name: const Constant(true),
    }));
  }

  // ===========================================================================
  // 业务查询
  // ===========================================================================

  /// 监听所有快捷方式 (联合 Activities 表)
  Stream<List<TypedResult>> watchAllWithActivity() {
    // 联合查询
    final query = select(activityShortcuts).join([
      innerJoin(
        activities,
        activities.id.equalsExp(activityShortcuts.activityId),
      )
    ]);

    // 过滤已删除 (Both Shortcut and Activity)
    query.where(activityShortcuts.deletedAt.isNull());
    query.where(activities.deletedAt.isNull());

    // 排序
    query.orderBy([
      OrderingTerm(expression: activityShortcuts.sortOrder, mode: OrderingMode.asc)
    ]);

    return query.watch();
  }

  /// 切换置顶状态 (Pin / Unpin)
  /// 智能处理: 插入 / 软删除 / 复活
  Future<void> toggleShortcut(String targetActivityId) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    // 1. 查本地状态 (包括已软删除的)
    final existing = await (select(activityShortcuts)
      ..where((t) => t.activityId.equals(targetActivityId)))
        .getSingleOrNull();

    if (existing == null) {
      // Case A: 不存在 -> 全新插入 (Pin)
      // 获取当前最大排序值，排在最后
      final maxOrderQuery = selectOnly(activityShortcuts)
        ..addColumns([activityShortcuts.sortOrder.max()]);
      final maxOrder = await maxOrderQuery.map((row) => row.read(activityShortcuts.sortOrder.max())).getSingle() ?? 0.0;

      await saveLocal(
        ActivityShortcutsCompanion.insert(
          activityId: targetActivityId,
          sortOrder: Value(maxOrder + 1000.0),
          // Sync Meta
          updatedAt: now,
          isDirty: const Value(true),
        )
      );
    } else if (existing.deletedAt == null) {
      // Case B: 存在且活着 -> 软删除 (Unpin)
      await deleteLocal(targetActivityId, now);
    } else {
      // Case C: 存在但已死 -> 复活 (Re-pin)
      // 使用 saveLocal 进行 Upsert/Update
      await saveLocal(
        ActivityShortcutsCompanion(
          activityId: Value(targetActivityId),
          deletedAt: const Value(null), // 复活
          updatedAt: Value(now),
          isDirty: const Value(true),
        )
      );
    }
  }
}