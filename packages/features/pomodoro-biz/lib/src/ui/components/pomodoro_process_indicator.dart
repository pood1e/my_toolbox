import 'dart:async';

import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';

class PomodoroProcessIndicator extends StatefulWidget {
  final Pomodoro pomodoro;
  final double size;

  const PomodoroProcessIndicator({
    super.key,
    required this.pomodoro,
    this.size = 260.0,
  });

  @override
  State<PomodoroProcessIndicator> createState() =>
      _PomodoroProcessIndicatorState();
}

class _PomodoroProcessIndicatorState extends State<PomodoroProcessIndicator> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.pomodoro;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // --- 1. 计算逻辑 ---
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final totalMs = p.endAt - p.startAt;
    final remainMs = p.endAt - nowMs;

    final progress = totalMs == 0 ? 0.0 : (remainMs / totalMs).clamp(0.0, 1.0);
    final remaining = remainMs > 0
        ? Duration(milliseconds: remainMs)
        : Duration.zero;

    // --- 2. 颜色逻辑 (修改点) ---
    // 不再区分红绿，统一使用主题的主色调
    final Color primaryColor = colorScheme.primary;

    // 轨道颜色：使用主色的低透明度版本，或者使用 surfaceContainerHighest
    final Color trackColor = primaryColor.withOpacity(0.15);

    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 组件 1: 背景图标
          _PomodoroTypeBackground(
            type: p.type,
            color: primaryColor, // 也是主题色
            size: widget.size * 0.6,
          ),

          // 组件 2: 进度轨道
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: 1.0,
              color: trackColor,
              strokeWidth: 16,
            ),
          ),

          // 组件 3: 实际进度
          SizedBox.expand(
            child: CircularProgressIndicator(
              value: progress,
              color: primaryColor,
              strokeWidth: 16,
              strokeCap: StrokeCap.round,
            ),
          ),

          // 组件 4: 中间信息
          Center(
            child: SizedBox(
              width: widget.size * 0.75,
              height: widget.size * 0.75,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 时间文本
                    _PomodoroTimerText(
                      remaining: remaining,
                      color: primaryColor,
                    ),
                    const SizedBox(height: 8),
                    // 状态标签
                    _PomodoroStatusBadge(type: p.type, color: primaryColor),
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
// 子组件 (保持逻辑，但颜色由父组件传入主题色)
// =========================================================

class _PomodoroTypeBackground extends StatelessWidget {
  final PomodoroType type;
  final Color color;
  final double size;

  const _PomodoroTypeBackground({
    required this.type,
    required this.color,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    IconData icon;
    switch (type) {
      case PomodoroType.focus:
        icon = Icons.psychology_outlined; // 建议用 outlined 版本更精致
        break;
      case PomodoroType.shortBreak:
        icon = Icons.coffee_outlined;
        break;
      case PomodoroType.longBreak:
        icon = Icons.weekend_outlined;
        break;
    }

    return Opacity(
      opacity: 0.1, // 背景图标稍微淡一点，不要抢视觉
      child: Icon(icon, size: size, color: color),
    );
  }
}

class _PomodoroStatusBadge extends StatelessWidget {
  final PomodoroType type;
  final Color color;

  const _PomodoroStatusBadge({required this.type, required this.color});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (type) {
      case PomodoroType.focus:
        label = '专注中';
        break;
      case PomodoroType.shortBreak:
        label = '短休息';
        break;
      case PomodoroType.longBreak:
        label = '长休息';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        // 背景色更淡，接近透明
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.0,
        ),
      ),
    );
  }
}

class _PomodoroTimerText extends StatelessWidget {
  final Duration remaining;
  final Color color;

  const _PomodoroTimerText({required this.remaining, required this.color});

  @override
  Widget build(BuildContext context) {
    final minutes = remaining.inMinutes
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final seconds = remaining.inSeconds
        .remainder(60)
        .toString()
        .padLeft(2, '0');
    final timeStr = '$minutes:$seconds';

    return Text(
      timeStr,
      style: Theme.of(context).textTheme.displayLarge?.copyWith(
        fontWeight: FontWeight.w800, // 字体加粗
        fontSize: 56, // 稍微加大字号
        color: color,
        fontFeatures: [const FontFeature.tabularFigures()],
      ),
    );
  }
}
