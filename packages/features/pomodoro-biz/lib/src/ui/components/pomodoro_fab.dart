import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../state/logical_state.dart';
import '../state/trigger_state.dart';
import '../state/ui_state.dart';
import 'create_session_dialog.dart';

/// 主入口：智能 FAB (三态切换)
class PomodoroFab extends ConsumerWidget {
  const PomodoroFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听状态
    final phase = ref.watch(currentPomodoroPhaseProvider);
    // 2. 获取数据
    final pomodoro = ref.watch(latestPomodoroProvider).value;

    // 3. 三态切换
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: switch (phase) {
        // A. 空闲态
        PomodoroPhase.idle => const _IdleFab(),

        // B. 进行态 (倒计时)
        PomodoroPhase.running => _RunningFab(pomodoro: pomodoro!),

        // C. 等待态 (已完成) - [新增独立组件]
        PomodoroPhase.pending => _PendingFab(pomodoro: pomodoro!),
      },
    );
  }
}

// =========================================================
// 组件 1: 空闲 FAB (新建)
// =========================================================
class _IdleFab extends StatelessWidget {
  const _IdleFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      key: const ValueKey('IdleFab'),
      heroTag: 'idle_fab',
      icon: const Icon(Icons.add_task_rounded),
      label: const Text('新建专注'),
      onPressed: () => CreateSessionDialog.show(context),
    );
  }
}

// =========================================================
// 组件 2: 运行 FAB (倒计时)
// =========================================================
class _RunningFab extends ConsumerWidget {
  final Pomodoro pomodoro;

  const _RunningFab({required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听倒计时 (每秒刷新)
    final timeLeft = ref.watch(timeLeftProvider);

    // 格式化
    final minutes = timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');

    final isFocus = pomodoro.type == PomodoroType.focus;
    final bgColor = isFocus ? Colors.red.shade100 : Colors.green.shade100;

    return FloatingActionButton.extended(
      key: const ValueKey('RunningFab'),
      heroTag: 'running_fab',
      backgroundColor: bgColor,
      foregroundColor: Colors.black87,
      elevation: 4,
      onPressed: () => _expandSheet(ref),
      icon: Icon(isFocus ? Icons.timer_outlined : Icons.coffee_outlined),
      label: Text(
        "$minutes:$seconds · ${isFocus ? '专注' : '休息'}",
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

// =========================================================
// 组件 3: 等待 FAB (已完成) - [新增]
// =========================================================
class _PendingFab extends ConsumerWidget {
  final Pomodoro pomodoro;

  const _PendingFab({required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 这是一个静止状态，不需要监听 timeLeftProvider

    final isFocus = pomodoro.type == PomodoroType.focus;

    // 样式：使用较深的颜色或灰色，表示"结算中"
    final theme = Theme.of(context);
    final bgColor = theme.colorScheme.surfaceContainerHighest;
    final fgColor = theme.colorScheme.onSurface;

    return FloatingActionButton.extended(
      key: const ValueKey('PendingFab'),
      heroTag: 'pending_fab',
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 2,
      // 稍微降低阴影，表示静止
      onPressed: () => _expandSheet(ref),
      // 点击依然打开面板，让用户去点"下一步"
      icon: const Icon(Icons.check_circle_outline),
      label: Text(
        isFocus ? '专注完成' : '休息结束',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

void _expandSheet(WidgetRef ref) {
  ref
      .read(pomodoroSheetControllerProvider)
      .animateTo(
        1.0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuart,
      );
}
