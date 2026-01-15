import 'pomodoro_domain.dart';

abstract class PomodoroService {
  /// 创建一个session并开始
  Future<Pomodoro> startSession(String name, String note);

  /// 结束上一个钟,开始下一个钟
  Future<Pomodoro> nextPhase(String id);

  /// 设置番茄钟结束时间为当前
  Future<void> stopPomodoro(String id);

  /// 延长番茄钟结束时间
  Future<void> extendPomodoro(String id, int seconds);

  /// 更新session信息
  Future<void> updateSession(String sessionId, String name, String? note);

  /// 进行中的
  Stream<Pomodoro?> watchProcessing();

  /// for debug
  Stream<List<Pomodoro>> watchAll();
}
