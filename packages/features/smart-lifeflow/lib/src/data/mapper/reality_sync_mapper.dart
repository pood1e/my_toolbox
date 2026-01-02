import 'package:drift/drift.dart';
import '../dtos/reality_dtos.dart';
import '../lifeflow_database.dart';

// --- 辅助：Drift Value 包装器 ---
Value<T> val<T>(T? x) => x == null ? const Value.absent() : Value(x);

// =============================================================================
// 1. Activity Sync Mapper
// =============================================================================
extension ActivityEntitySyncMapper on ActivityEntity {
  ActivityDto toDto() {
    return ActivityDto(
      id: id,
      name: name,
      icon: icon,
      colorHex: colorHex,

      // Sync Meta
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension ActivityDtoSyncMapper on ActivityDto {
  ActivitiesCompanion toCompanion({bool isDirty = false}) {
    return ActivitiesCompanion(
      id: Value(id),
      name: Value(name),
      icon: val(icon),
      colorHex: val(colorHex),

      // Sync Meta
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// =============================================================================
// 2. ActivityLog Sync Mapper
// =============================================================================
extension ActivityLogEntitySyncMapper on ActivityLogEntity {
  ActivityLogDto toDto() {
    return ActivityLogDto(
      id: id,
      activityId: activityId,
      startTime: startTime,
      endTime: endTime,
      note: note,

      // Sync Meta
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension ActivityLogDtoSyncMapper on ActivityLogDto {
  ActivityLogsCompanion toCompanion({bool isDirty = false}) {
    return ActivityLogsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      startTime: Value(startTime),
      endTime: val(endTime),
      note: val(note),

      // Sync Meta
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// =============================================================================
// 3. ActivityShortcut Sync Mapper
// =============================================================================
extension ActivityShortcutEntitySyncMapper on ActivityShortcutEntity {
  ActivityShortcutDto toDto() {
    return ActivityShortcutDto(
      // Shortcut 表主键是 activityId
      activityId: activityId,
      sortOrder: sortOrder,

      // Sync Meta (注意: Shortcut 表没有 createdAt 字段)
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension ActivityShortcutDtoSyncMapper on ActivityShortcutDto {
  ActivityShortcutsCompanion toCompanion({bool isDirty = false}) {
    return ActivityShortcutsCompanion(
      activityId: Value(activityId),
      sortOrder: Value(sortOrder),

      // Sync Meta
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}