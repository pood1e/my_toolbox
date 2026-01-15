import 'package:app_core/uuid.dart';
import 'package:framework_api/framework_api.dart';

import 'data/pomodoro_repository.dart';
import 'pomodoro_domain.dart';
import 'pomodoro_service.dart';

class PomodoroServiceImpl implements PomodoroService {
  final PomodoroRepository _repo;
  final ServerTimeService _serverTimeService;
  final Uuid _uuid = Uuid();

  // 纯逻辑配置
  static const int _focusDurationMin = 25;
  static const int _shortBreakDurationMin = 5;

  PomodoroServiceImpl({
    required PomodoroRepository repo,
    required ServerTimeService serverTimeService,
  }) : _repo = repo,
       _serverTimeService = serverTimeService;

  // todo: 确认是否按剩余时间刷新
  @override
  Stream<Pomodoro?> watchProcessing() =>
      _repo.watchActivePomodoro(_serverTimeService.nowMs);

  // todo: 确认是否按剩余时间刷新
  @override
  Stream<List<Pomodoro>> watchAll() =>
      _repo.watchHistory(_serverTimeService.nowMs);

  @override
  Future<Pomodoro> startSession(String name, String note) async {
    final now = DateTime.now();
    final endAt = now
        .add(const Duration(minutes: _focusDurationMin))
        .millisecondsSinceEpoch;
    final sessionId = _uuid.v4();
    final session = PomodoroSession(id: sessionId, name: name, note: note);
    await _repo.saveSession(session, _serverTimeService.nowMs);
    final pomodoro = Pomodoro(
      id: _uuid.v4(),
      session: session,
      startAt: now.millisecondsSinceEpoch,
      endAt: endAt,
      type: PomodoroType.focus,
    );

    // 只需要保存，不需要设置 Timer
    await _repo.savePomodoro(pomodoro, _serverTimeService.nowMs);
    return pomodoro;
  }

  @override
  Future<Pomodoro> nextPhase(String previousId) async {
    final previous = await _repo.getPomodoroById(previousId);

    if (previous == null) {
      // 如果按 ID 都查不到，说明数据真的出问题了
      throw Exception('任务不存在: $previousId');
    }

    // 停止旧的
    await stopPomodoro(previous.id);

    // 计算新的
    final nextType = previous.type == PomodoroType.focus
        ? PomodoroType.shortBreak
        : PomodoroType.focus;

    final duration = nextType == PomodoroType.focus
        ? _focusDurationMin
        : _shortBreakDurationMin;

    final now = DateTime.now();
    final endAt = now.add(Duration(minutes: duration)).millisecondsSinceEpoch;

    final nextPomodoro = Pomodoro(
      id: _uuid.v4(),
      session: previous.session,
      // 复用 Session
      startAt: now.millisecondsSinceEpoch,
      endAt: endAt,
      type: nextType,
    );

    await _repo.savePomodoro(nextPomodoro, _serverTimeService.nowMs);
    return nextPomodoro;
  }

  @override
  Future<void> stopPomodoro(String id) async {
    // 纯逻辑：将结束时间改为现在
    final now = DateTime.now().millisecondsSinceEpoch;
    await _repo.updatePomodoroEndTime(id, now, _serverTimeService.nowMs);
  }

  @override
  Future<void> extendPomodoro(String id, int seconds) async {
    final active = await _repo.getPomodoroById(id);
    if (active != null) {
      final newEndAt = active.endAt + (seconds * 1000);
      await _repo.updatePomodoroEndTime(id, newEndAt, _serverTimeService.nowMs);
    }
  }

  @override
  Future<void> updateSession(String sessionId, String name, String? note) {
    return _repo.updateSession(sessionId, name, note, _serverTimeService.nowMs);
  }
}
