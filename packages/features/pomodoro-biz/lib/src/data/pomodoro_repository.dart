import '../pomodoro_domain.dart';

/// ==========================================================
/// Repository 接口定义
/// ==========================================================
abstract class PomodoroRepository {
  // --- 查询 (Reads) ---

  /// 监听当前正在进行的番茄钟 (Stream)
  Stream<Pomodoro?> watchActivePomodoro(int tick);

  /// 监听所有历史记录 (Stream)
  Stream<List<Pomodoro>> watchHistory(int tick);

  /// 获取一个钟
  Future<Pomodoro?> getPomodoroById(String id);

  // --- 写入 (Writes) ---

  /// 保存一个新的 Session
  Future<void> saveSession(PomodoroSession session, int serverTime);

  /// 保存一个新的 Pomodoro (同时确保关联的 Session 存在)
  Future<void> savePomodoro(Pomodoro pomodoro, int serverTime);

  /// 更新 Session 的基本信息 (Name, Note)
  Future<void> updateSession(
    String id,
    String name,
    String? note,
    int serverTime,
  );

  /// 更新 Pomodoro 的结束时间 (用于 Stop 或 Extend)
  Future<void> updatePomodoroEndTime(String id, int newEndAt, int serverTime);
}
