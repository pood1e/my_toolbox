import 'dart:convert';

// lib/src/data/mappers/sync_mappers.dart

import 'package:drift/drift.dart';

import '../../domain/lifeflow_shared.dart';
import '../dtos/lifeflow_dtos.dart';
import '../lifeflow_database.dart';

// 引入数据库与DTO

// --- 辅助函数：Drift Value 包装器 ---
Value<T> val<T>(T? x) => x == null ? const Value.absent() : Value(x);

Value<T> valWithDefault<T>(T? x, T defaultValue) => Value(x ?? defaultValue);

// ==========================================
// 1. ActivityEntity (重命名后的)
// ==========================================
extension ActivityEntitySyncMapper on ActivityEntity {
  ActivityDto toDto() {
    return ActivityDto(
      id: id,
      name: name,
      icon: icon,
      colorHex: colorHex,
      isArchived: isArchived,
      defaultFocusMode: defaultFocusMode,
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
      isArchived: Value(isArchived),
      defaultFocusMode: Value(defaultFocusMode),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 2. Plan
// ==========================================
extension PlanSyncMapper on PlanEntity {
  PlanDto toDto() {
    return PlanDto(
      id: id,
      title: title,
      description: description,
      icon: icon,
      colorHex: colorHex,
      sortOrder: sortOrder,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension PlanDtoSyncMapper on PlanDto {
  PlansCompanion toCompanion({bool isDirty = false}) {
    return PlansCompanion(
      id: Value(id),
      title: Value(title),
      description: val(description),
      icon: val(icon),
      colorHex: val(colorHex),
      sortOrder: Value(sortOrder),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 3. TaskDefinition (含复杂对象)
// ==========================================
extension TaskDefinitionSyncMapper on TaskDefinitionEntity {
  TaskDefinitionDto toDto() {
    return TaskDefinitionDto(
      id: id,
      planId: planId,
      parentId: parentId,
      activityId: activityId,
      title: title,
      note: note,
      priority: priority.index,

      estimatedDuration: estimatedDuration,
      flexibility: flexibility.index,
      energyLevel: energyLevel,

      targetValue: targetValue,
      unit: unit,

      // Entity(Object) -> DTO(JSON String)
      recurrence: recurrence != null ? json.encode(recurrence!.toJson()) : null,
      reminderPolicy: reminderPolicy.index,

      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension TaskDefinitionDtoSyncMapper on TaskDefinitionDto {
  TaskDefinitionsCompanion toCompanion({bool isDirty = false}) {
    // DTO(JSON String) -> Companion(Object)
    // Drift 的 Converter 会负责后续将 Object 转回 DB JSON
    TaskRecurrence? recurrenceObj;
    if (recurrence != null) {
      try {
        recurrenceObj = TaskRecurrence.fromJson(json.decode(recurrence!));
      } catch (e) {
        // 容错
      }
    }

    return TaskDefinitionsCompanion(
      id: Value(id),
      planId: val(planId),
      parentId: val(parentId),
      activityId: val(activityId),
      title: Value(title),
      note: val(note),
      priority: Value(Priority.values[priority]),

      estimatedDuration: val(estimatedDuration),
      flexibility: Value(TimeFlexibility.values[flexibility]),
      energyLevel: Value(energyLevel),

      targetValue: Value(targetValue),
      unit: val(unit),

      recurrence: val(recurrenceObj),
      reminderPolicy: Value(ReminderPolicy.values[reminderPolicy]),

      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 4. TaskState
// ==========================================
extension TaskStateSyncMapper on TaskStateEntity {
  TaskStateDto toDto() {
    return TaskStateDto(
      id: taskId,
      // DB: taskId -> DTO: id
      currentValue: currentValue,
      status: status.index,
      startDate: startDate,
      dueDate: dueDate,
      updatedAt: updatedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension TaskStateDtoSyncMapper on TaskStateDto {
  TaskStatesCompanion toCompanion({bool isDirty = false}) {
    return TaskStatesCompanion(
      taskId: Value(id),
      // DTO: id -> DB: taskId
      currentValue: Value(currentValue),
      status: Value(TaskStatus.values[status]),
      startDate: val(startDate),
      dueDate: val(dueDate),
      updatedAt: Value(updatedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 5. ScheduleItem
// ==========================================
extension ScheduleItemSyncMapper on ScheduleItemEntity {
  ScheduleItemDto toDto() {
    return ScheduleItemDto(
      id: id,
      taskId: taskId,
      dateVal: date,
      sortOrder: sortOrder,
      plannedStart: plannedStart,
      plannedEnd: plannedEnd,
      status: status.index,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension ScheduleItemDtoSyncMapper on ScheduleItemDto {
  ScheduleItemsCompanion toCompanion({bool isDirty = false}) {
    return ScheduleItemsCompanion(
      id: Value(id),
      taskId: Value(taskId),
      date: Value(dateVal),
      sortOrder: Value(sortOrder),
      plannedStart: val(plannedStart),
      plannedEnd: val(plannedEnd),
      status: Value(ScheduleStatus.values[status]),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 6. ActivityLog
// ==========================================
extension ActivityLogSyncMapper on ActivityLogEntity {
  ActivityLogDto toDto() {
    return ActivityLogDto(
      id: id,
      activityId: activityId,
      taskId: taskId,
      scheduleItemId: scheduleItemId,
      startTime: startTime,
      endTime: endTime,
      timezoneOffset: timezoneOffset,
      logicalDate: logicalDate,
      source: source.index,
      sourceMetadata: sourceMetadata,
      isConfirmed: isConfirmed,
      value: value,
      note: note,
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
      taskId: val(taskId),
      scheduleItemId: val(scheduleItemId),
      startTime: Value(startTime),
      endTime: val(endTime),
      timezoneOffset: Value(timezoneOffset),
      logicalDate: Value(logicalDate),
      source: Value(LogSource.values[source]),
      sourceMetadata: val(sourceMetadata),
      isConfirmed: Value(isConfirmed),
      value: Value(value),
      note: val(note),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}

// ==========================================
// 7. DailySnapshot
// ==========================================
extension DailySnapshotSyncMapper on DailySnapshotEntity {
  DailySnapshotDto toDto() {
    return DailySnapshotDto(
      id: id,
      dateVal: date,
      energyStart: energyStart,
      energyEnd: energyEnd,
      review: review,
      // completionRate: completionRate,
      // focusMinutes: focusMinutes,
      createdAt: createdAt,
      updatedAt: updatedAt,
      deletedAt: deletedAt,
      serverUpdatedAt: serverUpdatedAt,
    );
  }
}

extension DailySnapshotDtoSyncMapper on DailySnapshotDto {
  DailySnapshotsCompanion toCompanion({bool isDirty = false}) {
    return DailySnapshotsCompanion(
      id: Value(id),
      date: Value(dateVal),
      energyStart: val(energyStart),
      energyEnd: val(energyEnd),
      review: val(review),
      // completionRate: val(completionRate),
      // focusMinutes: val(focusMinutes),
      updatedAt: Value(updatedAt),
      deletedAt: val(deletedAt),
      serverUpdatedAt: Value(serverUpdatedAt),
      isDirty: Value(isDirty),
    );
  }
}
