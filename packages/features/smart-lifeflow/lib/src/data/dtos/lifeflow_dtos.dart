import 'package:app_core/object.dart';

part 'lifeflow_dtos.freezed.dart';
part 'lifeflow_dtos.g.dart';

// --- 1. Activity ---
@freezed
abstract class ActivityDto with _$ActivityDto {
  const factory ActivityDto({
    required String id,
    required String name,
    String? icon,
    String? colorHex,
    @Default(false) bool isArchived,
    @Default(false) bool defaultFocusMode,

    // Sync Fields
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ActivityDto;

  factory ActivityDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityDtoFromJson(json);
}

// --- 2. Plan ---
@freezed
abstract class PlanDto with _$PlanDto {
  const factory PlanDto({
    required String id,
    required String title,
    String? description,
    String? icon,
    String? colorHex,
    @Default(0.0) double sortOrder,

    // Sync Fields
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _PlanDto;

  factory PlanDto.fromJson(Map<String, dynamic> json) =>
      _$PlanDtoFromJson(json);
}

// --- 3. TaskDefinition ---
@freezed
abstract class TaskDefinitionDto with _$TaskDefinitionDto {
  const factory TaskDefinitionDto({
    required String id,
    String? planId,
    String? parentId,
    String? activityId,

    required String title,
    String? note,
    @Default(0) int priority,

    // 智能调度
    int? estimatedDuration,
    @Default(1) int flexibility,
    @Default(0) int energyLevel,

    // 目标与规则
    @Default(1.0) double targetValue,
    String? unit,
    String? recurrence, // Raw JSON String
    @Default(1) int reminderPolicy,

    // Sync Fields
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _TaskDefinitionDto;

  factory TaskDefinitionDto.fromJson(Map<String, dynamic> json) =>
      _$TaskDefinitionDtoFromJson(json);
}

// --- 4. TaskState ---
@freezed
abstract class TaskStateDto with _$TaskStateDto {
  const factory TaskStateDto({
    required String id, // 对应 DB 中的 taskId

    @Default(0.0) double currentValue,
    @Default(0) int status,

    int? startDate,
    int? dueDate,

    // Sync Fields (注意：State 通常没有 deletedAt，随 Definition 删除)
    required int updatedAt,
    @Default(0) int serverUpdatedAt,
  }) = _TaskStateDto;

  factory TaskStateDto.fromJson(Map<String, dynamic> json) =>
      _$TaskStateDtoFromJson(json);
}

// --- 5. ScheduleItem ---
@freezed
abstract class ScheduleItemDto with _$ScheduleItemDto {
  const factory ScheduleItemDto({
    required String id,
    required String taskId,

    required int dateVal, // 服务端字段名为 dateVal 以避开 date 关键字

    @Default(0.0) double sortOrder,
    int? plannedStart,
    int? plannedEnd,
    @Default(0) int status,

    // Sync Fields
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ScheduleItemDto;

  factory ScheduleItemDto.fromJson(Map<String, dynamic> json) =>
      _$ScheduleItemDtoFromJson(json);
}

// --- 6. ActivityLog ---
@freezed
abstract class ActivityLogDto with _$ActivityLogDto {
  const factory ActivityLogDto({
    required String id,
    required String activityId,
    String? taskId,
    String? scheduleItemId,

    required int startTime,
    int? endTime,
    required int timezoneOffset,
    required int logicalDate,

    @Default(0) int source,
    String? sourceMetadata, // Raw JSON String
    @Default(true) bool isConfirmed,

    @JsonKey(name: 'valueVal') @Default(0.0) double value, // 对应服务端 valueVal
    String? note,

    // Sync Fields
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _ActivityLogDto;

  factory ActivityLogDto.fromJson(Map<String, dynamic> json) =>
      _$ActivityLogDtoFromJson(json);
}

// --- 7. DailySnapshot ---
@freezed
abstract class DailySnapshotDto with _$DailySnapshotDto {
  const factory DailySnapshotDto({
    required String id,
    required int dateVal,

    int? energyStart,
    int? energyEnd,
    String? review,

    double? completionRate,
    int? focusMinutes,

    // Sync Fields
    required int createdAt,
    required int updatedAt,
    int? deletedAt,
    @Default(0) int serverUpdatedAt,
  }) = _DailySnapshotDto;

  factory DailySnapshotDto.fromJson(Map<String, dynamic> json) =>
      _$DailySnapshotDtoFromJson(json);
}
