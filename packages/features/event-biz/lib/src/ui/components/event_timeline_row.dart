import 'package:app_core/utils.dart';
import 'package:common_ui/style.dart';
import 'package:event_api/event_api.dart';
import 'package:flutter/material.dart';

class EventTimelineRow extends StatelessWidget {
  final Event event;

  const EventTimelineRow({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    // 使用扩展方法获取主题配置
    final colors = context.colorScheme;
    final textTheme = context.textTheme;

    final dateTime = DateTime.fromMillisecondsSinceEpoch(event.timestamp);
    final style = SourceStyleMapper.getStyle(event.source);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 左侧：时间
          SizedBox(
            width: 60, // 保持布局宽度的稳定性，这个通常不需要变为 Spacing
            child: Padding(
              // 对齐右侧卡片内的第一行文字 (Card padding top + Text height adjustment)
              padding: const EdgeInsets.only(top: AppSpacings.l + 2),
              child: Text(
                DateFormat('HH:mm').format(dateTime),
                textAlign: TextAlign.center,
                style: textTheme.labelMedium?.copyWith(
                  color: colors.outline, // 使用 outline 颜色 (通常是灰色)
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          // 2. 中间：时间轴
          Stack(
            alignment: Alignment.center,
            children: [
              // 竖线
              Container(
                width: 2,
                color: colors.outlineVariant.withValues(alpha: AppAlpha.medium),
              ),
              // 圆点
              Container(
                margin: const EdgeInsets.only(top: AppSpacings.xs), // 微调对齐
                width: AppSpacings.m, // 12.0
                height: AppSpacings.m, // 12.0
                decoration: BoxDecoration(
                  color: style.color,
                  shape: BoxShape.circle,
                  // 边框颜色应与页面背景一致，形成“切割”效果
                  border: Border.all(color: context.pageBackground, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: style.color.withValues(alpha: AppAlpha.disabled),
                      // 0.3
                      blurRadius: 4,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // 3. 右侧：内容卡片
          Expanded(
            child: Padding(
              // 统一间距：左 m, 上 xs, 右 l, 下 l
              padding: const EdgeInsets.fromLTRB(
                AppSpacings.m,
                AppSpacings.xs,
                AppSpacings.l,
                AppSpacings.l,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surfaceContainerLow, // 稍微区分于页面背景
                  borderRadius: AppRadius.card, // 12.0
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacings.m), // 卡片内部间距
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header: Icon + Source
                      Row(
                        children: [
                          Icon(style.icon, size: 14, color: style.color),
                          Gaps.h4, // 4.0
                          Text(
                            event.source.toUpperCase(),
                            style: textTheme.labelSmall?.copyWith(
                              color: style.color,
                              fontWeight: FontWeight.bold,
                              fontSize: 10, // 特殊小字号保持原样或定义在 Theme 中
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),

                      Gaps.v8, // 8.0
                      // Content: Name
                      Text(
                        event.name,
                        style: textTheme.bodyMedium?.copyWith(
                          color: colors.onSurface,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- 辅助：Source 样式映射器 ---

class SourceStyle {
  final Color color;
  final IconData icon;

  const SourceStyle(this.color, this.icon);
}

class SourceStyleMapper {
  static SourceStyle getStyle(String source) {
    switch (source.toLowerCase()) {
      case 'manual':
        return const SourceStyle(Colors.blue, Icons.edit_note);
      case 'bilibili':
        return const SourceStyle(Colors.pink, Icons.tv);
      case 'github':
        return const SourceStyle(Colors.black87, Icons.code);
      case 'health':
        return const SourceStyle(Colors.green, Icons.directions_run);
      case 'transaction':
      case 'alipay':
      case 'wechat_pay':
        return const SourceStyle(Colors.orange, Icons.attach_money);
      default:
        // 根据 source 字符串生成一个确定的随机色（可选）
        return const SourceStyle(Colors.grey, Icons.circle);
    }
  }
}
