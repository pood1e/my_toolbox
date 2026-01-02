import 'package:drift/drift.dart';
import 'package:framework_api/framework_api.dart';

import 'table_shared.dart';

@DataClassName('ActivityEntity')
class Activities extends CoreSyncTable with AuditTable {
  TextColumn get name => text()();

  TextColumn get icon => text().nullable()();

  TextColumn get colorHex => text().nullable()();
}

@DataClassName('ActivityLogEntity')
class ActivityLogs extends CoreSyncTable
    with AuditTable, LwwWithIdSyncTable, SoftDeleteSyncTable {
  TextColumn get activityId =>
      text().references(Activities, #id, onDelete: KeyAction.cascade)();

  IntColumn get startTime => integer()();

  IntColumn get endTime => integer().nullable()();

  TextColumn get note => text().nullable()();
}

// =============================================================================
// ActivityShortcut (活动快捷方式/置顶)
// =============================================================================
@DataClassName('ActivityShortcutEntity')
class ActivityShortcuts extends Table with LwwSyncTable, SoftDeleteSyncTable {
  TextColumn get activityId =>
      text().references(Activities, #id, onDelete: KeyAction.cascade)();

  // 排序权重 (用户手动拖拽排序)
  RealColumn get sortOrder => real().withDefault(const Constant(0.0))();

  @override
  Set<Column> get primaryKey => {activityId};
}
