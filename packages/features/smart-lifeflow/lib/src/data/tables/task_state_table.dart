import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';
import 'task_definition_table.dart';

@DataClassName('TaskStateEntity')
class TaskStates extends Table {
  // 1:1 强关联 Definition
  TextColumn get taskId => text().references(TaskDefinitions, #id)();

  // --- 动态进度 ---
  RealColumn get currentValue => real().withDefault(const Constant(0.0))();

  // 状态流转 (Active / Completed)
  IntColumn get status =>
      integer().map(const EnumIndexConverter(TaskStatus.values))();

  // --- 动态时间轴 (UTC Millis) ---
  IntColumn get startDate => integer().nullable()();

  IntColumn get dueDate => integer().nullable()();

  // --- Sync Fields ---
  // 这里的 updatedAt 独立于 Definition，打卡不影响 Definition 的版本
  IntColumn get updatedAt => integer()();

  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {taskId};
}
