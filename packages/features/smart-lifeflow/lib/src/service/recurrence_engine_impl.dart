import '../domain/lifeflow_shared.dart';
import 'recurrence_engine.dart';

class RecurrenceEngineImpl implements RecurrenceEngine {
  @override
  bool isDue(
    TaskRecurrence rule, {
    required DateTime targetDate,
    DateTime? lastDoneDate,
    required DateTime createdAt,
  }) {
    // 0. 基础前置检查
    // 如果设置了 until，且目标日期已过，不命中
    if (rule.until != null && targetDate.millisecondsSinceEpoch > rule.until!) {
      return false;
    }

    // 1. 分模式处理
    switch (rule.mode) {
      case RecurrenceMode.fixed:
        return _checkFixedDue(rule, targetDate, createdAt);

      case RecurrenceMode.flexible:
        // Flexible 模式下，整个周期内每一天都是 Due 的
        // 只要当天没有超过上次完成的周期
        return _checkFlexibleDue(rule, targetDate, lastDoneDate);

      case RecurrenceMode.relative:
        // Relative 模式取决于上一次完成的具体日期
        return _checkRelativeDue(rule, targetDate, lastDoneDate, createdAt);
    }
  }

  @override
  DateTime? getNextDueDate(
    TaskRecurrence rule, {
    required DateTime lastDoneDate,
  }) {
    // 根据频率和间隔计算下一次
    switch (rule.frequency) {
      case RecurrenceFrequency.daily:
        return lastDoneDate.add(Duration(days: rule.interval));
      case RecurrenceFrequency.weekly:
        return lastDoneDate.add(Duration(days: 7 * rule.interval));
      case RecurrenceFrequency.monthly:
        return DateTime.utc(
          lastDoneDate.year,
          lastDoneDate.month + rule.interval,
          lastDoneDate.day,
        );
      case RecurrenceFrequency.yearly:
        return DateTime.utc(
          lastDoneDate.year + rule.interval,
          lastDoneDate.month,
          lastDoneDate.day,
        );
    }
  }

  // ===========================================================================
  // 模式私有逻辑
  // ===========================================================================

  /// 固定日逻辑 (e.g. 每周一、三、五)
  bool _checkFixedDue(TaskRecurrence rule, DateTime target, DateTime start) {
    // 1. 检查间隔 (Interval)
    // 计算目标日与创建日之间的周期数
    final diffDays = target.difference(_normalize(start)).inDays;
    if (diffDays < 0) return false;

    // 2. 检查具体的日子
    if (rule.frequency == RecurrenceFrequency.daily) {
      return diffDays % rule.interval == 0;
    }

    if (rule.frequency == RecurrenceFrequency.weekly) {
      // 检查间隔周
      final weeksDiff = (diffDays / 7).floor();
      if (weeksDiff % rule.interval != 0) return false;

      // 检查周几 (Dart: 1=Mon, 7=Sun)
      if (rule.byWeekDays != null && rule.byWeekDays!.isNotEmpty) {
        return rule.byWeekDays!.contains(target.weekday);
      }
      // 默认创建日的那一天
      return target.weekday == start.weekday;
    }

    if (rule.frequency == RecurrenceFrequency.monthly) {
      // 检查月偏移
      final monthDiff =
          (target.year - start.year) * 12 + (target.month - start.month);
      if (monthDiff % rule.interval != 0) return false;

      if (rule.byMonthDays != null && rule.byMonthDays!.isNotEmpty) {
        // 处理 -1 (最后一天)
        if (rule.byMonthDays!.contains(-1)) {
          final lastDay = DateTime.utc(target.year, target.month + 1, 0).day;
          if (target.day == lastDay) return true;
        }
        return rule.byMonthDays!.contains(target.day);
      }
      return target.day == start.day;
    }

    return false;
  }

  /// 弹性配额逻辑 (e.g. 每周 3 次)
  bool _checkFlexibleDue(
    TaskRecurrence rule,
    DateTime target,
    DateTime? lastDone,
  ) {
    if (lastDone == null) return true;

    // 获取 target 所在的周期范围
    final range = getPeriodRange(rule.frequency, target);

    // 如果上次完成时间在当前周期之前，则当前周期一定 Due
    return lastDone.isBefore(range.start);

    // 注意：具体的次数判断（是否已经满了 3 次）不在引擎层判断，
    // 引擎层只判断“这周该不该出现”，Service 层会通过 TaskState.currentValue 判断是否完成。
  }

  /// 相对循环逻辑 (e.g. 做完 3 天后再次生成)
  bool _checkRelativeDue(
    TaskRecurrence rule,
    DateTime target,
    DateTime? lastDone,
    DateTime created,
  ) {
    // 如果从未做过，从创建日开始算
    final baseDate = _normalize(lastDone ?? created);

    // 下一次应做日期 = 基准日 + 间隔
    final nextDue = _addInterval(baseDate, rule.frequency, rule.interval);

    // 只要目标日期 >= 下一次应做日期，就命中
    return target.isAtSameMomentAs(nextDue) || target.isAfter(nextDue);
  }

  // ===========================================================================
  // 辅助方法
  // ===========================================================================

  @override
  DateTimeRange getPeriodRange(RecurrenceFrequency freq, DateTime date) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return DateTimeRange(date, date);
      case RecurrenceFrequency.weekly:
        // 找到本周一
        final start = date.subtract(Duration(days: date.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return DateTimeRange(_normalize(start), _normalize(end));
      case RecurrenceFrequency.monthly:
        final start = DateTime.utc(date.year, date.month, 1);
        final end = DateTime.utc(date.year, date.month + 1, 0);
        return DateTimeRange(start, end);
      case RecurrenceFrequency.yearly:
        final start = DateTime.utc(date.year, 1, 1);
        final end = DateTime.utc(date.year, 12, 31);
        return DateTimeRange(start, end);
    }
  }

  DateTime _normalize(DateTime dt) => DateTime.utc(dt.year, dt.month, dt.day);

  DateTime _addInterval(DateTime base, RecurrenceFrequency freq, int interval) {
    switch (freq) {
      case RecurrenceFrequency.daily:
        return base.add(Duration(days: interval));
      case RecurrenceFrequency.weekly:
        return base.add(Duration(days: 7 * interval));
      case RecurrenceFrequency.monthly:
        return DateTime.utc(base.year, base.month + interval, base.day);
      case RecurrenceFrequency.yearly:
        return DateTime.utc(base.year + interval, base.month, base.day);
    }
  }
}
