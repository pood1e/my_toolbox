import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import 'activity_presets.dart';

/// 展示这个活动在列表或时间轴上的样子
class ActivityPreviewCard extends StatelessWidget {
  final String name;
  final String icon;
  final String colorHex;

  const ActivityPreviewCard({
    super.key,
    required this.name,
    required this.icon,
    required this.colorHex,
  });

  @override
  Widget build(BuildContext context) {
    final color = ActivityColors.fromHex(colorHex);

    return Container(
      // 使用语义化间距: 垂直 XL (24), 水平 L (16)
      padding: const EdgeInsets.symmetric(
        vertical: AppSpacings.xl,
        horizontal: AppSpacings.l,
      ),
      decoration: BoxDecoration(
        color: context.colorScheme.surface,
        borderRadius: AppRadius.card, // 统一卡片圆角
        boxShadow: AppShadows.card(context.colorScheme), // 统一阴影
      ),
      child: Column(
        children: [
          Text(
            '预览 (Preview)',
            style: context.textTheme.labelSmall?.copyWith(
              // 🆕 使用 AppAlpha.high (0.5) 代替 opacity
              color: context.colorScheme.onSurface.withValues(
                alpha: AppAlpha.high,
              ),
            ),
          ),
          Gaps.v12, // 统一垂直间隔
          Row(
            children: [
              // 图标容器
              Container(
                width: AppSizes.iconBoxMedium,
                // 48.0
                height: AppSizes.iconBoxMedium,
                decoration: BoxDecoration(
                  // 动态计算背景色: 主色 + Medium Alpha (0.15)
                  color: color.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.all(AppRadius.circleL), // 12.0
                  border: Border.all(
                    color: color.withValues(alpha: AppAlpha.high),
                    width: 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  icon.isEmpty ? '?' : icon,
                  style: context.textTheme.headlineSmall,
                ),
              ),
              Gaps.h16, // 统一水平间隔
              // 名称与模拟时间
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name.isEmpty ? '活动名称' : name,
                      style: context.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gaps.v4,
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: context.colorScheme.onSurface.withValues(
                          alpha: AppAlpha.low,
                        ),
                        borderRadius: BorderRadius.all(
                          AppRadius.circleM,
                        ), // 8.0
                      ),
                      child: Text(
                        '00:00 - 00:00',
                        style: context.textTheme.labelSmall?.copyWith(
                          fontSize: 10,
                          color: context.colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_vert, color: context.colorScheme.outline),
            ],
          ),
        ],
      ),
    );
  }
}
