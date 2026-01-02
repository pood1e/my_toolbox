import '../domain/lifeflow_shared.dart';

abstract class RecurrenceEngine {
  /// 1. 判断任务在指定日期 [targetDate] 是否“命中”复发规则
  /// [targetDate]: 逻辑归属日 (UTC 0点)
  /// [lastDoneDate]: 该任务上一次【彻底完成】的逻辑日期
  /// [createdAt]: 任务创建日期 (用于计算 Fixed 模式的起始偏移)
  bool isDue(
    TaskRecurrence rule, {
    required DateTime targetDate,
    DateTime? lastDoneDate,
    required DateTime createdAt,
  });

  /// 2. 计算任务在 [lastDoneDate] 完成后的“下一次”预计截止日期
  /// 用于更新 TaskState.dueDate
  DateTime? getNextDueDate(
    TaskRecurrence rule, {
    required DateTime lastDoneDate,
  });

  /// 3. 获取 [targetDate] 所在的周期范围 (开始和结束时间)
  /// 主要用于 Flexible 模式判断“本周”或“本月”
  DateTimeRange getPeriodRange(
    RecurrenceFrequency frequency,
    DateTime targetDate,
  );
}

class DateTimeRange {
  final DateTime start;
  final DateTime end;

  DateTimeRange(this.start, this.end);
}
