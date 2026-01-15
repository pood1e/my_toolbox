import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../pomodoro_state.dart';

class PomodoroOperationArea extends ConsumerWidget {
  final Pomodoro pomodoro;

  const PomodoroOperationArea({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 根据当前类型判断逻辑
    final isFocus = pomodoro.type == PomodoroType.focus;

    // 配置：下一步操作的文案和图标
    final String nextLabel = isFocus ? '休息' : '继续专注';
    final IconData nextIcon = isFocus
        ? Icons.coffee_rounded
        : Icons.play_arrow_rounded;

    // 配置：主题色
    final Color nextBtnColor = isFocus
        ? Colors
              .green
              .shade100 // 专注时显示绿色按钮去休息
        : Colors.red.shade100; // 休息时显示红色按钮去专注

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start, // 顶部对齐防止文字换行导致高度不一致
      children: [
        // 1. 结束会话 (Stop)
        _OpBtn(
          icon: Icons.stop_rounded,
          label: '结束会话',
          bgColor: Theme.of(context).colorScheme.surfaceContainerHighest,
          iconColor: Theme.of(context).colorScheme.onSurface,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            await service.stopPomodoro(pomodoro.id);
          },
        ),

        // 2. 延长 5 分钟 (+5)
        _OpBtn(
          icon: Icons.update_rounded,
          label: '+5 分钟',
          bgColor: Colors.orange.shade100,
          iconColor: Colors.orange.shade900,
          onTap: () async {
            final service = await ref.read(pomodoroServiceProvider.future);
            // 延长 300 秒
            await service.extendPomodoro(pomodoro.id, 5 * 60);
          },
        ),

        // 3. 下一步 (Next: 休息/继续)
        _OpBtn(
          icon: nextIcon,
          label: nextLabel,
          bgColor: nextBtnColor,
          iconColor: Colors.black87,
          isPrimary: true,
          // 标记为主要按钮，稍微大一点
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
// 内部私有组件：圆形操作按钮
// =========================================================

class _OpBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const _OpBtn({
    required this.icon,
    required this.label,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    // 主要按钮稍微大一点，突出显示
    final double size = isPrimary ? 72.0 : 64.0;
    final double iconSize = isPrimary ? 32.0 : 28.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: bgColor,
          shape: const CircleBorder(), // 圆形
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            // 增加点击水波纹效果
            splashColor: Colors.black12,
            child: SizedBox(
              width: size,
              height: size,
              child: Icon(icon, size: iconSize, color: iconColor),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: isPrimary ? FontWeight.bold : FontWeight.normal,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
