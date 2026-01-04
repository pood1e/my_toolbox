// File: src/ui/screens/activity_management_screen.dart
import 'package:app_core/di.dart';
import 'package:common_ui/style.dart';
import 'package:flutter/material.dart';

import '../../domain/reality_models.dart';
import '../../state/activity_state.dart';
import '../components/activity/activity_presets.dart';
import 'edit_activity_screen.dart';

class ActivityManagementScreen extends ConsumerWidget {
  const ActivityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听活动列表数据流
    final activitiesAsync = ref.watch(allActivitiesProvider);

    return Scaffold(
      backgroundColor: context.pageBackground, // 1. 使用主题扩展背景色
      appBar: AppBar(
        title: const Text('活动管理'),
        centerTitle: false,
        backgroundColor: context.colorScheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        // 防止滚动时变色
        titleTextStyle: context.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.bold,
          color: context.colorScheme.onSurface,
        ),
      ),
      body: activitiesAsync.when(
        data: (activities) {
          if (activities.isEmpty) {
            return _buildEmptyState(context);
          }
          return ListView.separated(
            // 2. 使用语义化页面边距 (24.0)
            padding: const EdgeInsets.all(AppSpacings.page),
            itemCount: activities.length,
            // 3. 使用 Gaps 替代 SizedBox
            separatorBuilder: (_, __) => Gaps.v12,
            itemBuilder: (context, index) {
              return _ActivityListItem(activity: activities[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '加载失败: $err',
            style: TextStyle(color: context.colorScheme.error),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // 跳转到新建页面 (不传 ID)
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditActivityScreen()),
          );
        },
        backgroundColor: context.colorScheme.primary,
        elevation: 4,
        icon: Icon(Icons.add, color: context.colorScheme.onPrimary),
        label: Text(
          '新建活动',
          style: TextStyle(
            color: context.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dashboard_customize_outlined,
            size: 64,
            // 使用 withValues 替代 withOpacity
            color: context.colorScheme.outline.withValues(
              alpha: AppAlpha.disabled,
            ),
          ),
          Gaps.v16,
          Text(
            '这里空空如也',
            style: context.textTheme.titleLarge?.copyWith(
              color: context.colorScheme.onSurface.withValues(
                alpha: AppAlpha.high,
              ),
              fontWeight: FontWeight.bold,
            ),
          ),
          Gaps.v8,
          Text(
            '创建你的第一个活动分类\n开始记录生活流',
            textAlign: TextAlign.center,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.outline,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityListItem extends StatelessWidget {
  final Activity activity;

  const _ActivityListItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    final color = ActivityColors.fromHex(activity.colorHex);

    return InkWell(
      onTap: () {
        // 跳转到编辑页面 (传入 ID)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => EditActivityScreen(activityId: activity.id),
          ),
        );
      },
      borderRadius: AppRadius.card, // 统一圆角
      child: Container(
        decoration: BoxDecoration(
          color: context.colorScheme.surface,
          borderRadius: AppRadius.card,
          boxShadow: AppShadows.card(context.colorScheme), // 统一阴影
        ),
        // 统一卡片内边距 (16.0)
        padding: const EdgeInsets.all(AppSpacings.card),
        child: Row(
          children: [
            // 图标容器
            Container(
              width: AppSizes.iconBoxMedium + 2,
              // 微调尺寸
              height: AppSizes.iconBoxMedium + 2,
              decoration: BoxDecoration(
                // 背景色：品牌色 + 15% 透明度
                color: color.withValues(alpha: AppAlpha.medium),
                borderRadius: BorderRadius.all(AppRadius.circleL), // 12.0
              ),
              alignment: Alignment.center,
              child: Text(
                activity.icon ?? '?',
                style: context.textTheme.headlineSmall,
              ),
            ),

            Gaps.h16, // 水平间距
            // 文本信息
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activity.name,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                  // 这里预留一行，未来可以显示 "本周记录 3 次" 等统计信息
                ],
              ),
            ),

            // 箭头图标
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: context.colorScheme.outline.withValues(
                alpha: AppAlpha.disabled,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
