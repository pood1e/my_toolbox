import 'package:drift/drift.dart';

import '../../domain/reality_models.dart';
import '../lifeflow_database.dart'; // 引入 Drift 生成的类

// --- 辅助：时间转换 (强制 UTC) ---
// 数据库存的是 UTC 毫秒时间戳 (int)
// Domain 用的是 DateTime (UTC)

DateTime toDt(int ms) => DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

DateTime? toDtOrNull(int? ms) =>
    ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

int toMs(DateTime dt) => dt.millisecondsSinceEpoch;

int? toMsOrNull(DateTime? dt) => dt?.millisecondsSinceEpoch;

// =============================================================================
// 1. Activity (行为分类)
// =============================================================================
extension ActivityEntityDomainMapper on ActivityEntity {
  Activity toDomain() {
    return Activity(
      id: id,
      name: name,
      icon: icon,
      colorHex: colorHex,
      updatedAt: toDt(updatedAt),
    );
  }
}

extension ActivityDomainToCompanion on Activity {
  ActivitiesCompanion toCompanion({bool dirty = true}) {
    // 注意: Domain 对象通常不包含 createdAt (因为它不可变)，
    // 但 Update 操作需要 ID 和 updatedAt
    return ActivitiesCompanion(
      id: Value(id),
      name: Value(name),
      icon: Value(icon),
      colorHex: Value(colorHex),
      updatedAt: Value(toMs(updatedAt)),
      isDirty: Value(dirty),
    );
  }
}

// =============================================================================
// 2. ActivityLog (行为流水)
// =============================================================================
extension ActivityLogEntityDomainMapper on ActivityLogEntity {
  ActivityLog toDomain() {
    return ActivityLog(
      id: id,
      activityId: activityId,
      startTime: toDt(startTime),
      endTime: toDtOrNull(endTime),
      note: note,
      createdAt: toDt(createdAt),
    );
  }
}

extension ActivityLogDomainToCompanion on ActivityLog {
  ActivityLogsCompanion toCompanion({bool dirty = true}) {
    return ActivityLogsCompanion(
      id: Value(id),
      activityId: Value(activityId),
      startTime: Value(toMs(startTime)),
      endTime: Value(toMsOrNull(endTime)),
      note: Value(note),

      // createdAt 在 Log 中很重要，通常用于排序
      createdAt: Value(toMs(createdAt)),
      // Log 修改时更新 updatedAt (虽然 Log 很少改)
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      isDirty: Value(dirty),
    );
  }
}

// =============================================================================
// 3. ActivityShortcut (快捷方式)
// =============================================================================
extension ActivityShortcutEntityDomainMapper on ActivityShortcutEntity {
  ActivityShortcut toDomain() {
    return ActivityShortcut(
      activityId: activityId,
      sortOrder: sortOrder,
      updatedAt: toDt(updatedAt),
    );
  }
}

// Shortcut 通常不需要 Domain -> Companion 的完整转换，
// 因为它的写操作通常是特定的 toggle/reorder 方法直接构建 Companion。
