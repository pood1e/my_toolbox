import 'package:app_core/object.dart';

import 'lifeflow_shared.dart';

part 'lifeflow_models.freezed.dart';

// --- 1. Activity (行为定义) ---
@freezed
abstract class Activity with _$Activity {
  const factory Activity({
    required String id,
    required String name,
    String? icon,
    String? colorHex,

    @Default(false) bool isArchived,
    @Default(false) bool defaultFocusMode,

    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Activity;
}

// --- 2. Plan (清单) ---
@freezed
abstract class Plan with _$Plan {
  const factory Plan({
    required String id,
    required String title,
    String? description,

    String? icon,
    String? colorHex,
    @Default(0.0) double sortOrder,

    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Plan;
}

// --- 3. Task (聚合实体：定义 + 状态) ---
// 注意：移除了 tags 字段
@freezed
abstract class Task with _$Task {
  const factory Task({
    required String id,

    // --- 归属 ---
    String? planId, // Nullable (Inbox)
    String? parentId,
    String? defaultActivityId, // 默认行为分类
    // --- 定义 (Definition) ---
    required String title,
    String? note,
    @Default(Priority.none) Priority priority,

    // 智能属性
    int? estimatedDuration, // mins
    @Default(TimeFlexibility.flexible) TimeFlexibility flexibility,
    @Default(0) int energyLevel,

    // 目标与规则
    @Default(1.0) double targetValue,
    String? unit,
    TaskRecurrence? recurrence,
    @Default(ReminderPolicy.atStart) ReminderPolicy reminderPolicy,

    // --- 状态 (State) ---
    @Default(0.0) double currentValue,
    @Default(TaskStatus.active) TaskStatus status,

    // 动态时间轴 (当前周期的)
    DateTime? startDate,
    DateTime? dueDate,

    // --- Meta ---
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _Task;
}

// --- 4. ScheduleItem (每日计划) ---
@freezed
abstract class ScheduleItem with _$ScheduleItem {
  const factory ScheduleItem({
    required String id,
    required String taskId,

    // 逻辑日 (UTC 0点)
    required DateTime date,

    // 规划结果
    @Default(0.0) double sortOrder,
    DateTime? plannedStart,
    DateTime? plannedEnd,

    // 状态快照
    @Default(ScheduleStatus.pending) ScheduleStatus status,

    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ScheduleItem;
}

// --- 5. ActivityLog (行为流水) ---
// 注意：移除了 adHocTags 字段
@freezed
abstract class ActivityLog with _$ActivityLog {
  const ActivityLog._();

  const factory ActivityLog({
    required String id,

    // 必填：做了什么性质的事
    required String activityId,

    // 选填：为了哪个目标/计划
    String? taskId,
    String? scheduleItemId,

    // --- 时间轴 ---
    required DateTime startTime,
    DateTime? endTime,
    // 本地时区偏移 (分钟)
    required int timezoneOffset,
    // 逻辑归属日
    required DateTime logicalDate,

    // --- 内容 ---
    @Default(LogSource.manual) LogSource source,
    Map<String, dynamic>? sourceMetadata,
    @Default(true) bool isConfirmed,

    @Default(0.0) double value,
    String? note,

    // --- Meta ---
    required DateTime createdAt,
    required DateTime updatedAt,
    DateTime? deletedAt,
  }) = _ActivityLog;

  // 持续时长 getter
  Duration get duration =>
      endTime == null ? Duration.zero : endTime!.difference(startTime);
}
