import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../../providers.dart';
import '../state/logical_state.dart';

class PomodoroOperationArea extends ConsumerWidget {
  final Pomodoro pomodoro;

  const PomodoroOperationArea({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiState = ref.watch(currentPomodoroPhaseProvider);

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      // 使用缩放+淡入淡出，切换时更自然
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: uiState == PomodoroPhase.running
          ? RunningOperationButtons(pomodoro: pomodoro)
          : WaitingOperationButtons(pomodoro: pomodoro),
    );
  }
}

// =========================================================
// 组件 1: 进行中按钮组 (Running)
// 包含: [结束] [+5分钟] [跳过]
// =========================================================
class RunningOperationButtons extends ConsumerWidget {
  final Pomodoro pomodoro;

  const RunningOperationButtons({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFocus = pomodoro.type == PomodoroType.focus;

    final nextLabel = isFocus ? '去休息' : '去专注';
    final nextIcon = isFocus ? Icons.coffee_rounded : Icons.play_arrow_rounded;
    final nextColor = isFocus ? Colors.green.shade100 : Colors.red.shade100;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // 1. 停止
        _CircleOpBtn(
          icon: Icons.stop_rounded,
          label: '结束',
          bgColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          iconColor: Theme.of(context).colorScheme.onSurface,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.stopPomodoro(pomodoro.id);
            await service.closeSession(pomodoro.session.id);
          },
        ),

        // 2. 延长
        _CircleOpBtn(
          icon: Icons.update_rounded,
          label: '+5 分钟',
          bgColor: Colors.orange.shade100,
          iconColor: Colors.orange.shade900,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.extendPomodoro(pomodoro.id, 5 * 60);
          },
        ),

        // 3. 跳过 (Next Phase)
        _CircleOpBtn(
          icon: nextIcon,
          label: nextLabel,
          bgColor: nextColor,
          iconColor: Colors.black87,
          isPrimary: true,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.nextPhase(pomodoro.id);
          },
        ),
      ],
    );
  }
}

// =========================================================
// 组件 2: 等待中按钮组 (Waiting/Pending)
// 包含: [关闭] [开始下一阶段(大按钮)]
// =========================================================
class WaitingOperationButtons extends ConsumerWidget {
  final Pomodoro pomodoro;

  const WaitingOperationButtons({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextLabel = '开始专注';
    final nextIcon = Icons.play_arrow_rounded;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 8,
      children: [
        // 1. 关闭会话
        _CircleOpBtn(
          icon: Icons.stop_rounded,
          label: '结束',
          bgColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          iconColor: Theme.of(context).colorScheme.onSurface,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.closeSession(pomodoro.session.id);
          },
        ),

        _CircleOpBtn(
          icon: nextIcon,
          label: nextLabel,
          bgColor: Colors.green.shade100,
          iconColor: Colors.black87,
          isPrimary: true,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.nextPhase(pomodoro.id);
          },
        ),
      ],
    );
  }
}

// =========================================================
// 共享组件: 圆形按钮基础样式
// =========================================================
class _CircleOpBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const _CircleOpBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final double btnSize = isPrimary ? 72.0 : 64.0;
    final double iconSize = isPrimary ? 32.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          shape: const CircleBorder(),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            splashColor: Colors.black12,
            child: SizedBox(
              width: btnSize,
              height: btnSize,
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
