import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';
import 'converters.dart';
import 'plan_table.dart';

class TaskDefinitions extends Table {
  TextColumn get id => text()(); // UUID

  // 归属 (Nullable 支持 Inbox 模式)
  TextColumn get planId => text().nullable().references(Plans, #id)();

  TextColumn get parentId =>
      text().nullable().references(TaskDefinitions, #id)();

  // --- 内容 ---
  TextColumn get title => text()();

  TextColumn get note => text().nullable()();

  IntColumn get priority =>
      integer().map(const EnumIndexConverter(Priority.values))();

  // 注意：Tags 已移除，使用 TaskTagRelations 表

  // --- 智能调度 ---
  IntColumn get estimatedDuration => integer().nullable()(); // 分钟
  IntColumn get flexibility =>
      integer().map(const EnumIndexConverter(TimeFlexibility.values))();

  IntColumn get energyLevel => integer().withDefault(const Constant(0))();

  // --- 进度目标 (Static) ---
  RealColumn get targetValue => real().withDefault(const Constant(1.0))();

  TextColumn get unit => text().nullable()();

  // --- 规则 (JSON) ---
  TextColumn get recurrence =>
      text().map(const RecurrenceJsonConverter()).nullable()();

  IntColumn get reminderPolicy => integer()
      .map(const EnumIndexConverter(ReminderPolicy.values))
      .withDefault(const Constant(1))(); // 假设 1 是 atStart

  // --- Sync Fields ---
  IntColumn get createdAt => integer()();

  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
