import 'package:drift/drift.dart';

@DataClassName('PlanEntity')
class Plans extends Table {
  TextColumn get id => text()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  // UI 配置
  TextColumn get icon => text().nullable()();
  TextColumn get colorHex => text().nullable()();

  // 排序：使用 Double 支持分数排序 (虽然清单排序频率低，但保持统一)
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();

  // --- 同步与审计 (SyncBase) ---
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()(); // 业务时间 (LWW)
  IntColumn get deletedAt => integer().nullable()(); // 软删除墓碑
  IntColumn get serverUpdatedAt => integer().withDefault(const Constant(0))(); // 增量游标
  BoolColumn get isDirty => boolean().withDefault(const Constant(true))(); // 待上传

  @override
  Set<Column> get primaryKey => {id};


}