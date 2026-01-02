import 'package:app_core/object.dart';
import 'package:flutter/foundation.dart';

part 'reality_models.freezed.dart';
part 'reality_models.g.dart';

// =============================================================================
// 1. Activity (行为分类)
// =============================================================================
/// 定义了"做什么" (What)。
/// 这是一个静态的分类字典，不包含状态。
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String name,

    // UI 表现
    String? icon,
    String? colorHex,

    // Sync Meta
    required DateTime updatedAt,
  }) = _Activity;

  factory Activity.fromJson(Map<String, dynamic> json) =>
      _$ActivityFromJson(json);
}

// =============================================================================
// 2. ActivityLog (行为流水)
// =============================================================================
/// 定义了"发生了什么" (Facts)。
/// 这是一个纯净的时间记录，只包含 [时间] 和 [分类]。
/// 具体的"产出/贡献" (Impact) 由 TaskLogRelation 承担 (Bridge Model)。
@freezed
abstract class ActivityLog with _$ActivityLog {
  //以此支持自定义 getter
  const ActivityLog._();

  const factory ActivityLog({
    required String id,
    required String activityId,

    // 物理时间轴 (UTC)
    required DateTime startTime,
    DateTime? endTime, // Null 表示正在进行中 (Ongoing)
    // 备注 (对这次行为的描述)
    String? note,

    // Sync Meta (Log 创建后极少修改，createdAt 很重要)
    required DateTime createdAt,
  }) = _ActivityLog;

  /// 计算持续时长
  /// 如果正在进行中，则计算到当前时刻的间隔
  Duration get duration {
    final end = endTime ?? DateTime.now().toUtc();
    return end.difference(startTime);
  }

  factory ActivityLog.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogFromJson(json);
}

// =============================================================================
// 3. ActivityShortcut (快捷方式)
// =============================================================================
/// 定义了"UI 如何排列"。
/// 这是一个纯 UI 辅助模型，用于快速开始页面。
@freezed
abstract class ActivityShortcut with _$ActivityShortcut {
  const factory ActivityShortcut({
    required String activityId,

    // 排序权重
    @Default(0.0) double sortOrder,

    // Sync Meta
    required DateTime updatedAt,
  }) = _ActivityShortcut;

  factory ActivityShortcut.fromJson(Map<String, dynamic> json) =>
      _$ActivityShortcutFromJson(json);
}
