import 'package:app_core/di.dart';
import 'package:flutter/material.dart';

import '../../state/activity_state.dart';
import 'edit_activity_screen.dart';

class ActivityManagementScreen extends ConsumerWidget {
  const ActivityManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. 监听 allActivitiesProvider
    final activitiesAsync = ref.watch(allActivitiesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('管理活动')),
      body: activitiesAsync.when(
        // 2. 处理数据、加载、错误三种状态
        data: (activities) {
          if (activities.isEmpty) {
            return const Center(child: Text('还没有活动，点击右下角添加一个吧！'));
          }
          return ListView.builder(
            itemCount: activities.length,
            itemBuilder: (context, index) {
              final activity = activities[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Color(
                    int.parse('0xFF${activity.colorHex ?? 'CCCCCC'}'),
                  ),
                  child: Text(activity.icon ?? '📝'),
                ),
                title: Text(activity.name),
                trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                onTap: () {
                  // 3. 点击跳转到编辑页
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          EditActivityScreen(activityId: activity.id),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('加载失败: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // 4. 点击 FAB 跳转到新建页 (不传 activityId)
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const EditActivityScreen()));
        },
      ),
    );
  }
}
