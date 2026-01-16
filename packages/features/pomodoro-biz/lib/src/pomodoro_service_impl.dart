import 'package:app_core/logger.dart';
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

  @override
  Stream<Pomodoro?> watchLatest() => _repo.watchLatest();

  @override
  Stream<List<Pomodoro>> watchAll() => _repo.watchAll();

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
    // 1. 获取上一条记录
    final previous = await _repo.getPomodoroById(previousId);
    if (previous == null) throw Exception('任务上下文丢失');

    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    // ============================================================
    // [新增核心逻辑] 自动延长休息时间
    // ============================================================
    // 条件：
    // 1. 上一个是休息 (ShortBreak 或 LongBreak)
    // 2. 当前时间已经超过了原本的计划结束时间 (即处于 Pending 拖延状态)
    // 3. 我们正准备开始下一个阶段 (Start Focus)
    if (previous.type != PomodoroType.focus && nowMs > previous.endAt) {
      logger.i('自动延长休息时间: 增加 ${(nowMs - previous.endAt) / 1000} 秒');

      // 更新上一条记录的结束时间为"现在"
      await _repo.updatePomodoroEndTime(
        previous.id,
        nowMs,
        _serverTimeService.nowMs,
      );
    }

    // 2. 停止上一条 (如果还在 Running 状态，这一步会把 endAt 截断到 now；
    //    如果是 Pending 状态且是休息，上面已经更新过 endAt=Now 了，这里再 update 一次也无妨，
    //    或者加个判断避免重复写入。为了代码简单，直接调用也没问题，Drift 会处理)
    //
    //    优化：如果上面已经延长了，其实不需要 stop 了。
    //    但为了逻辑通用性，保留 stop 逻辑处理 "Focus -> Break" 的情况。
    if (previous.endAt > nowMs) {
      await stopPomodoro(previous.id);
    }

    // 3. 计算下一阶段类型
    // 逻辑：专注 -> 短休息；休息 -> 专注
    final nextType = previous.type == PomodoroType.focus
        ? PomodoroType.shortBreak
        : PomodoroType.focus;

    final duration = nextType == PomodoroType.focus
        ? _focusDurationMin
        : _shortBreakDurationMin;

    // 4. 创建新记录
    final endAt = now.add(Duration(minutes: duration)).millisecondsSinceEpoch;

    final nextPomodoro = Pomodoro(
      id: _uuid.v4(),
      session: previous.session,
      // 复用 Session
      startAt: nowMs,
      // 从现在开始
      endAt: endAt,
      type: nextType,
    );

    // 5. 保存
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

  @override
  Future<void> closeSession(String sessionId) async {
    await _repo.closeSession(sessionId, _serverTimeService.nowMs);
  }
}
