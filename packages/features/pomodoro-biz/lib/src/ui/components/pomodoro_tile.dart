import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';

class PomodoroTile extends StatelessWidget {
  final Pomodoro pomodoro;

  const PomodoroTile({super.key, required this.pomodoro});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isFocus = pomodoro.type == PomodoroType.focus;

    // 颜色定义
    final Color primaryColor = isFocus
        ? Colors.red.shade600
        : Colors.green.shade600;
    final Color containerColor = isFocus
        ? Colors.red.shade50
        : Colors.green.shade50;

    // 标题逻辑
    String titleText = pomodoro.type == PomodoroType.focus
        ? pomodoro.session.name
        : (pomodoro.type == PomodoroType.shortBreak ? '短休息' : '长休息');

    // 时间段格式化 (HH:mm)
    final dateFormat = DateFormat('HH:mm');
    final startStr = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(pomodoro.startAt),
    );
    final endStr = dateFormat.format(
      DateTime.fromMillisecondsSinceEpoch(pomodoro.endAt),
    );

    // 获取格式化后的时长文本
    final durationText = _formatDuration(
      Duration(milliseconds: pomodoro.endAt - pomodoro.startAt),
    );

    return ListTile(
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),

      // 左侧图标
      leading: Icon(
        isFocus ? Icons.psychology_alt : Icons.spa,
        color: primaryColor.withOpacity(0.8),
        size: 24,
      ),

      // 标题
      title: Text(
        titleText,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          fontSize: 15,
        ),
      ),

      // 副标题：起止时间
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Text(
          '$startStr - $endStr',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.hintColor,
            fontSize: 12,
            fontFeatures: [const FontFeature.tabularFigures()],
          ),
        ),
      ),

      // 右侧：中文时长
      trailing: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          durationText,
          style: TextStyle(
            color: primaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 13, // 稍微调小一点以适应长文本
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    // 1. 获取总分钟数
    int totalMinutes = duration.inMinutes;

    // 2. 规则：不足一分钟就显示1分钟
    // 如果总分钟是0，但其实有秒数（比如30秒），或者完全是0，都强制显示1分钟
    // (通常番茄钟记录不会是0秒，防止只有几秒的记录显示0分钟)
    if (totalMinutes < 1) {
      totalMinutes = 1;
    }

    // 3. 计算小时和剩余分钟
    final int hours = totalMinutes ~/ 60; // 取整除
    final int minutes = totalMinutes % 60; // 取余数

    // 4. 拼接字符串
    if (hours > 0) {
      if (minutes > 0) {
        return '$hours小时$minutes分钟'; // 例如: 1小时10分钟
      } else {
        return '$hours小时'; // 例如: 1小时
      }
    } else {
      return '$totalMinutes分钟'; // 例如: 25分钟
    }
  }
}
