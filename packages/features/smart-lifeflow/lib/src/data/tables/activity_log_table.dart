import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';
import 'activity_table.dart';
import 'schedule_item_table.dart';
import 'task_definition_table.dart';

class ActivityLogs extends Table {
  TextColumn get id => text()();

  // ✅ 必须关联活动 (回答 "What did you do?")
  TextColumn get activityId => text().references(Activities, #id)();

  // ✅ 可选关联任务 (回答 "For what goal?")
  // 即兴活动(Ad-hoc) 可以为 NULL
  TextColumn get taskId => text().nullable().references(TaskDefinitions, #id)();

  // 可选关联计划
  TextColumn get scheduleItemId => text().nullable().references(ScheduleItems, #id)();

  // --- 物理时间 ---
  IntColumn get startTime => integer()();
  IntColumn get endTime => integer().nullable()();
  IntColumn get timezoneOffset => integer()();

  // --- 逻辑归属 ---
  IntColumn get logicalDate => integer()();

  // --- 智能记录 ---
  IntColumn get source => integer().map(const EnumIndexConverter(LogSource.values))();
  TextColumn get sourceMetadata => text().nullable()(); // JSON
  BoolColumn get isConfirmed => boolean().withDefault(const Constant(true))();

  // --- 内容 ---
  RealColumn get value => real().withDefault(const Constant(0.0))();
  // 具体的文字描述 (如果 taskId 为空，这里就是主要描述，如"遛狗")
  TextColumn get note => text().nullable()();

  // --- Sync Fields ---
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  IntColumn get deletedAt => integer().nullable()();
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override Set<Column> get primaryKey => {id};
}