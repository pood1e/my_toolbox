import 'package:drift/drift.dart';

class Activities extends Table {
  TextColumn get id => text()();

  // 基础信息
  TextColumn get name => text()(); // e.g. "睡眠", "工作"
  TextColumn get icon => text().nullable()();

  TextColumn get colorHex => text().nullable()();

  // 归档 (不常用的活动可以隐藏，但不删除)
  BoolColumn get isArchived => boolean().withDefault(const Constant(false))();

  // 默认属性 (用于快速开始)
  // 当用户点击此活动开始计时，默认是否开启免打扰？默认标签？
  BoolColumn get defaultFocusMode =>
      boolean().withDefault(const Constant(false))();

  // Sync
  IntColumn get updatedAt => integer()();

  IntColumn get deletedAt => integer().nullable()();

  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))();

  BoolColumn get isDirty => boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}
