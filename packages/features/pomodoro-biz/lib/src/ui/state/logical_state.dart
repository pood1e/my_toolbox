import 'package:app_core/di.dart';

import '../../pomodoro_domain.dart';
import 'trigger_state.dart';

part 'logical_state.g.dart';

@riverpod
PomodoroPhase currentPomodoroPhase(Ref ref) {
  // 1. 监听数据源
  final pomodoroAsync = ref.watch(latestPomodoroProvider);
  final pomodoro = pomodoroAsync.value;

  // 2. 监听时间源 (每秒触发本函数重新运行)
  final nowAsync = ref.watch(tickerProvider);
  final now = nowAsync.value ?? DateTime.now().millisecondsSinceEpoch;

  if (pomodoro == null ||
      pomodoro.session.manualClosed ||
      now - pomodoro.endAt > 30 * 60 * 1000) {
    // logger.i('idle');
    return PomodoroPhase.idle;
  }

  if (now < pomodoro.endAt) {
    // logger.i('running');
    return PomodoroPhase.running;
  } else {
    // logger.i('pending');
    return PomodoroPhase.pending;
  }
}

@riverpod
Duration timeLeft(Ref ref) {
  final pomodoro = ref.watch(latestPomodoroProvider).value;
  if (pomodoro == null) {
    return Duration.zero;
  }
  final now =
      ref.watch(tickerProvider).value ?? DateTime.now().millisecondsSinceEpoch;
  final remainingMs = pomodoro.endAt - now;
  return remainingMs > 0 ? Duration(milliseconds: remainingMs) : Duration.zero;
}
