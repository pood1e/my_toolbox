import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';
import 'task_definition_table.dart';

class ScheduleItems extends Table {
  TextColumn get id => text()();

  TextColumn get taskId => text().references(TaskDefinitions, #id)();

  // 逻辑日锚点 (UTC 0点)
  IntColumn get date => integer()();

  // --- 规划核心 ---
  // 排序权重 (两两对比算法结果)
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();

  // 时间盒 (绝对时间)
  IntColumn get plannedStart => integer().nullable()();

  IntColumn get plannedEnd => integer().nullable()();

  // 状态快照
  IntColumn get status =>
      integer().map(const EnumIndexConverter(ScheduleStatus.values))();

  // Sync
  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
