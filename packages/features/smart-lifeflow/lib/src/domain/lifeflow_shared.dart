import 'package:app_core/object.dart';

part 'lifeflow_shared.freezed.dart';
part 'lifeflow_shared.g.dart';

enum TaskStatus {
  active, // 进行中
  completed, // 完成
  archived, // 归档
  deleted, // 软删除
}

enum ScheduleStatus {
  pending, // 待办
  done, // 完成
  migrated, // 推迟/迁出
}

enum Priority { none, low, medium, high }

enum TimeFlexibility {
  fixed, // 固定 (锚点)
  flexible, // 弹性 (水流)
}

enum LogSource {
  manual, // 手动
  timer, // 计时器
  suggestion, // 自动识别建议
  thirdParty, // HealthKit等
}

enum ReminderPolicy { none, atStart, fiveMinBefore, tenMinBefore, custom }

enum RecurrenceFrequency { daily, weekly, monthly, yearly }

enum RecurrenceMode {
  fixed, // 固定日程 (日历)
  flexible, // 弹性配额 (每周3次)
  relative, // 相对循环 (做完后X天)
}

// --- 转换器 (供 TaskRecurrence 和 DTO 使用) ---

class DateTimeMillisConverter implements JsonConverter<DateTime, int> {
  const DateTimeMillisConverter();

  @override
  DateTime fromJson(int json) =>
      DateTime.fromMillisecondsSinceEpoch(json, isUtc: true);

  @override
  int toJson(DateTime object) => object.millisecondsSinceEpoch;
}

// --- 值对象 (Value Object) ---
// 它需要在 DB 中存为 JSON，所以保留 fromJson/toJson

@freezed
abstract class TaskRecurrence with _$TaskRecurrence {
  const factory TaskRecurrence({
    required RecurrenceFrequency frequency,
    @Default(1) int interval,

    @Default(RecurrenceMode.fixed) RecurrenceMode mode,

    // Mode.fixed
    List<int>? byWeekDays,
    List<int>? byMonthDays,

    // Mode.flexible
    @Default(1) int flexibleQuota,

    // End conditions (UTC Millis)
    int? until,
    int? count,
  }) = _TaskRecurrence;

  factory TaskRecurrence.fromJson(Map<String, dynamic> json) =>
      _$TaskRecurrenceFromJson(json);
}
