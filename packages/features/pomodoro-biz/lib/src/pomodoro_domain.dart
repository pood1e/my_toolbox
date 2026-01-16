import 'package:app_core/object.dart';

part 'pomodoro_domain.freezed.dart';

enum PomodoroType { focus, shortBreak, longBreak }

@freezed
abstract class Pomodoro with _$Pomodoro {
  const factory Pomodoro({
    required String id,
    required PomodoroSession session,
    required int startAt,
    required int endAt,
    required PomodoroType type,
  }) = _Pomodoro;
}

@freezed
abstract class PomodoroSession with _$PomodoroSession {
  const factory PomodoroSession({
    required String id,
    required String name,
    String? note,
    @Default(false) bool manualClosed
  }) = _PomodoroSession;
}

enum PomodoroPhase {
  running, // 进行中
  pending, // 时间到，等待操作 (结算中)
  idle, // 超时/已归档
}