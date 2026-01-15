import 'dart:async';

import 'package:app_core/di.dart';
import 'package:app_core/logger.dart';
import 'package:flutter/material.dart';
import 'package:framework_api/framework_api.dart';

import '../data/pomodoro_dao.dart';
import '../data/pomodoro_repository.dart';
import '../data/pomodoro_repository_impl.dart';
import '../pomodoro_domain.dart';
import '../pomodoro_service.dart';
import '../pomodoro_service_impl.dart';

part 'pomodoro_state.g.dart';

@riverpod
Future<PomodoroRepository> pomodoroRepository(Ref ref) async {
  final dao = await ref.watch(pomodoroDaoProvider.future);
  final sessionDao = await ref.watch(pomodoroSessionDaoProvider.future);
  return PomodoroRepositoryImpl(pomodoroDao: dao, sessionDao: sessionDao);
}

@riverpod
Future<PomodoroService> pomodoroService(Ref ref) async {
  return PomodoroServiceImpl(
    repo: await ref.watch(pomodoroRepositoryProvider.future),
    serverTimeService: await ref.watch(serverTimeServiceProvider.future),
  );
}

@riverpod
Stream<Pomodoro?> activePomodoro(Ref ref) async* {
  final service = await ref.watch(pomodoroServiceProvider.future);
  yield* service.watchProcessing();
}

@riverpod
Stream<List<Pomodoro>> pomodoroHistory(Ref ref) async* {
  final service = await ref.watch(pomodoroServiceProvider.future);
  yield* service.watchAll();
}

// 全局唯一的 Sheet 控制器，用于在 FAB 点击时控制面板展开/收起
@riverpod
Raw<DraggableScrollableController> pomodoroSheetController(Ref ref) {
  return DraggableScrollableController();
}

/// 生命周期管理器 (AutoDispose 版本)
/// 职责：监听 Active Pomodoro，维护自动结束的 Timer
@riverpod
class PomodoroLifecycleManager extends _$PomodoroLifecycleManager {
  Timer? _timer;

  @override
  void build() {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    final activeAsync = ref.watch(activePomodoroProvider);

    activeAsync.when(
      data: (pomodoro) => _handleStateChange(pomodoro),
      loading: () => _timer?.cancel(),
      error: (err, stack) => _timer?.cancel(),
    );
  }

  Future<void> _onTimerComplete(Pomodoro pomodoro) async {
    final service = await ref.read(pomodoroServiceProvider.future);
    if (pomodoro.type == PomodoroType.focus) {
      // 场景 A: 专注结束 -> 自动进入下一阶段 (休息)
      logger.i('✅ 专注结束，自动开启休息...');

      await service.nextPhase(pomodoro.id);

      // 注意: nextPhase 内部会创建新的 Pomodoro 并保存到数据库
      // LifecycleManager 会监听到数据库变化，自动为这个新的休息设置定时器
    } else {
      // 场景 B: 休息结束 -> 停止 (等待用户手动开启下一个专注)
      logger.i('✅ 休息结束，停止计时，等待用户手动开始...');
      await service.stopPomodoro(pomodoro.id);
    }
  }

  void _handleStateChange(Pomodoro? pomodoro) {
    _timer?.cancel();
    _timer = null;

    if (pomodoro == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = pomodoro.endAt - now;

    if (remainingMs > 0) {
      // 1. 还在进行中：设置定时器
      _timer = Timer(Duration(milliseconds: remainingMs), () async {
        try {
          await _onTimerComplete(pomodoro);
        } catch (e) {
          logger.e('❌ 自动流转失败: $e');
        }
      });
    } else {
      // 2. 已经过期
      Future.microtask(() async {
        try {
          // 同样调用 onTimerComplete 处理过期逻辑
          await _onTimerComplete(pomodoro);
        } catch (e) {
          logger.e('❌ 过期处理失败: $e');
        }
      });
    }
  }
}
