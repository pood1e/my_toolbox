import 'dart:async';

import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../pomodoro_state.dart';
import 'create_session_dialog.dart';

/// 主入口：智能 FAB
class PomodoroFab extends ConsumerWidget {
  const PomodoroFab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听全局状态
    final asyncState = ref.watch(activePomodoroProvider);

    return asyncState.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (pomodoro) {
        final bool isActive = pomodoro != null;

        // 2. 使用动画切换两个不同的 Widget
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, anim) {
            // 缩放 + 旋转的切换效果会很灵动
            return ScaleTransition(scale: anim, child: child);
          },
          child: isActive
              ? _ActiveFab(pomodoro: pomodoro) // 状态: 进行中
              : const _IdleFab(), // 状态: 空闲
        );
      },
    );
  }
}

/// 子组件 1: 空闲状态 (新建按钮)
class _IdleFab extends StatelessWidget {
  const _IdleFab();

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      key: const ValueKey('IdleFab'),
      // 这里的 Key 用于 AnimatedSwitcher 识别变化
      heroTag: 'idle_fab',
      // 防止 Hero 动画冲突
      icon: const Icon(Icons.add_task_rounded),
      label: const Text('新建专注'),
      onPressed: () => CreateSessionDialog.show(context),
    );
  }
}

/// 子组件 2: 活跃状态 (倒计时按钮)
class _ActiveFab extends ConsumerStatefulWidget {
  final Pomodoro pomodoro;

  const _ActiveFab({required this.pomodoro});

  @override
  ConsumerState<_ActiveFab> createState() => _ActiveFabState();
}

class _ActiveFabState extends ConsumerState<_ActiveFab> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 启动局部 Timer，每秒刷新 UI 以更新倒计时
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. 计算倒计时
    final now = DateTime.now().millisecondsSinceEpoch;
    final remainingMs = widget.pomodoro.endAt - now;
    final duration = remainingMs > 0
        ? Duration(milliseconds: remainingMs)
        : Duration.zero;

    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    // 2. 状态判断
    final isFocus = widget.pomodoro.type == PomodoroType.focus;
    final statusText = isFocus ? '专注' : '休息';

    // 3. 样式配置
    final bgColor = isFocus ? Colors.red.shade100 : Colors.green.shade100;
    final fgColor = Colors.black87;

    return FloatingActionButton.extended(
      key: const ValueKey('ActiveFab'),
      heroTag: 'active_fab',
      backgroundColor: bgColor,
      foregroundColor: fgColor,
      elevation: 4,
      // 点击展开面板
      onPressed: () {
        ref
            .read(pomodoroSheetControllerProvider)
            .animateTo(
              1.0,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeOutQuart,
            );
      },
      icon: Icon(isFocus ? Icons.timer_outlined : Icons.coffee_outlined),
      label: Text(
        '$minutes:$seconds · $statusText',
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          // 关键：使用等宽数字，防止倒计时秒数变化时文字抖动
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
