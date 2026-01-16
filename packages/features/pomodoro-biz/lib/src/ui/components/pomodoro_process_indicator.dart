import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../state/logical_state.dart';

class PomodoroProcessIndicator extends ConsumerWidget {
  final Pomodoro pomodoro;
  final double size;

  const PomodoroProcessIndicator({
    super.key,
    required this.pomodoro,
    this.size = 200.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听低频状态 (Running / Pending)
    // 只有当状态改变时 (例如倒计时结束瞬间)，整个大组件才会 Rebuild 一次
    final phase = ref.watch(currentPomodoroPhaseProvider);

    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final trackColor = primaryColor.withOpacity(0.15);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // === 静态层 (不随倒计时刷新) ===

          // 1. 背景图标
          _BackgroundIcon(
            type: pomodoro.type,
            color: primaryColor,
            size: size * 0.5,
          ),

          // 2. 轨道
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              color: trackColor,
              strokeWidth: 16,
            ),
          ),

          // === 动态层 (内部局部刷新) ===

          // 3. 智能进度条
          SizedBox.expand(
            child: _SmartProgressRing(
              pomodoro: pomodoro,
              phase: phase,
              color: primaryColor,
            ),
          ),

          // 4. 中间文字区域
          Center(
            child: SizedBox(
              width: size * 0.70,
              height: size * 0.70,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 智能倒计时文字
                    _SmartTimerText(
                      pomodoro: pomodoro,
                      phase: phase,
                      color: primaryColor,
                    ),

                    const SizedBox(height: 8),

                    // 状态标签 (只随 Phase 变，不随倒计时变)
                    _StatusBadge(
                      type: pomodoro.type,
                      phase: phase,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =========================================================
// 组件 1: 智能进度环 (动静分离)
// =========================================================
class _SmartProgressRing extends StatelessWidget {
  final Pomodoro pomodoro;
  final PomodoroPhase phase;
  final Color color;

  const _SmartProgressRing({
    required this.pomodoro,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 策略：如果是 Pending，直接返回静态 Widget，完全不消耗 Riverpod 资源
    if (phase == PomodoroPhase.pending) {
      return CircularProgressIndicator(
        value: 1.0, // 满圈
        color: color,
        strokeWidth: 16,
        strokeCap: StrokeCap.round,
      );
    }

    // 只有在 Running 时，才使用 Consumer 监听时间
    return _DynamicRing(
      totalMs: pomodoro.endAt - pomodoro.startAt,
      color: color,
    );
  }
}

/// 私有组件：仅负责监听时间并更新进度
class _DynamicRing extends ConsumerWidget {
  final int totalMs;
  final Color color;

  const _DynamicRing({required this.totalMs, required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // !!! 只有这里会每秒 Rebuild !!!
    final timeLeft = ref.watch(timeLeftProvider);

    final progress = totalMs == 0
        ? 0.0
        : (timeLeft.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return CircularProgressIndicator(
      value: progress,
      color: color,
      strokeWidth: 16,
      strokeCap: StrokeCap.round,
    );
  }
}

// =========================================================
// 组件 2: 智能文字 (动静分离)
// =========================================================
class _SmartTimerText extends StatelessWidget {
  final Pomodoro pomodoro;
  final PomodoroPhase phase;
  final Color color;

  const _SmartTimerText({
    required this.pomodoro,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    // 策略：Pending 状态显示固定的总时长
    if (phase == PomodoroPhase.pending) {
      final totalDuration = Duration(
        milliseconds: pomodoro.endAt - pomodoro.startAt,
      );
      return _FormattedText(duration: totalDuration, color: color);
    }

    // Running 状态：使用 Consumer 监听时间
    return _DynamicTimerText(color: color);
  }
}

/// 私有组件：仅负责监听时间并更新文字
class _DynamicTimerText extends ConsumerWidget {
  final Color color;

  const _DynamicTimerText({required this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // !!! 只有这里会每秒 Rebuild !!!
    final timeLeft = ref.watch(timeLeftProvider);
    return _FormattedText(duration: timeLeft, color: color);
  }
}

/// 纯展示组件：格式化样式
class _FormattedText extends StatelessWidget {
  final Duration duration;
  final Color color;

  const _FormattedText({required this.duration, required this.color});

  @override
  Widget build(BuildContext context) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');

    return Text(
      "$minutes:$seconds",
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800,
        fontSize: 64,
        color: color,
        // 等宽数字
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }
}

// =========================================================
// 组件 3: 静态背景与标签 (保持不变)
// =========================================================

class _StatusBadge extends StatelessWidget {
  final PomodoroType type;
  final PomodoroPhase phase;
  final Color color;

  const _StatusBadge({
    required this.type,
    required this.phase,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    String label;
    if (phase == PomodoroPhase.pending) {
      label = type == PomodoroType.focus ? "专注完成" : "休息结束";
    } else {
      switch (type) {
        case PomodoroType.focus:
          label = "专注中";
          break;
        case PomodoroType.shortBreak:
          label = "短休息";
          break;
        case PomodoroType.longBreak:
          label = "长休息";
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _BackgroundIcon extends StatelessWidget {
  final PomodoroType type;
  final Color color;
  final double size;

  const _BackgroundIcon({
    required this.type,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case PomodoroType.focus:
        icon = Icons.psychology_outlined;
        break;
      case PomodoroType.shortBreak:
        icon = Icons.coffee_outlined;
        break;
      case PomodoroType.longBreak:
        icon = Icons.weekend_outlined;
        break;
    }
    return Opacity(
      opacity: 0.05,
      child: Icon(icon, size: size, color: color),
    );
  }
}
