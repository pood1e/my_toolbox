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
    // 1. 资源清理
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });

    // 2. 监听数据源
    // watch 会确保当 activePomodoro 变化时，build 重新执行，Timer 被重置
    final activeAsync = ref.watch(activePomodoroProvider);

    activeAsync.when(
      data: (pomodoro) => _handleStateChange(pomodoro),
      loading: () => _timer?.cancel(), // 加载中先取消定时器，防止误判
      error: (err, stack) => _timer?.cancel(),
    );
  }

  void _handleStateChange(Pomodoro? pomodoro) {
    // 先取消旧的
    _timer?.cancel();
    _timer = null;

    if (pomodoro == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = pomodoro.endAt - now;

    if (remainingMs > 0) {
      // A. 还在进行中：设置定时器
      // print("⏰ 自动结束倒计时: ${remainingMs / 1000}秒");
      _timer = Timer(Duration(milliseconds: remainingMs), () async {
        // --- 关键修改点 1: 异步获取 Service ---
        try {
          final service = await ref.read(pomodoroServiceProvider.future);
          await service.stopPomodoro(pomodoro.id);
          logger.i('✅ 定时器触发: 自动停止成功');
        } catch (e) {
          logger.e('❌ 自动停止失败: $e', error: e);
        }
      });
    } else {
      // B. 已经过期：立即停止
      // print("⚠️ 任务已过期，立即触发停止");

      // 使用 microtask 避免在 build 期间产生副作用
      Future.microtask(() async {
        // --- 关键修改点 2: 异步获取 Service ---
        try {
          final service = await ref.read(pomodoroServiceProvider.future);
          await service.stopPomodoro(pomodoro.id);
        } catch (e) {
          logger.e('❌ 过期停止失败: $e', error: e);
        }
      });
    }
  }
}
