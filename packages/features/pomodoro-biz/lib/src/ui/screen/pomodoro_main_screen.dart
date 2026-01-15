import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../components/pomodoro_fab.dart';
import '../components/pomodoro_tile.dart';
import '../pomodoro_state.dart';
import 'pomodoro_screen.dart';

class PomodoroMainScreen extends ConsumerWidget {
  const PomodoroMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        Scaffold(
          // 1. 带 BackBtn 的 AppBar
          appBar: AppBar(
            leading: const BackButton(), // 显式返回按钮
            title: const Text('番茄专注'),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // 更多设置...
                },
              ),
            ],
          ),

          // 2. 使用 Stack 叠加布局
          body: const _HistoryListSection(),

          // 3. 智能 FAB
          floatingActionButton: const PomodoroFab(),
        ),

        // 顶层: 可下拉的番茄钟面板
        // (这个组件内部会监听状态，无任务时自动隐藏)
        const PomodoroScreen(),
      ],
    );
  }
}

/// 内部组件: 处理历史记录列表的获取与渲染
class _HistoryListSection extends ConsumerWidget {
  const _HistoryListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(pomodoroHistoryProvider);

    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('加载失败: $err')),
      data: (history) {
        if (history.isEmpty) {
          return const _EmptyStatePlaceholder();
        }

        // 按日期分组: Map<DateTime, List<Pomodoro>>
        // 需要 import 'package:collection/collection.dart';
        final grouped = groupBy(history, (Pomodoro p) {
          final date = DateTime.fromMillisecondsSinceEpoch(p.startAt);
          return DateTime(date.year, date.month, date.day);
        });

        return ListView.builder(
          // !!! 关键: 底部留出空间给 FAB 和 MiniBar
          padding: const EdgeInsets.only(bottom: 120, top: 8),
          itemCount: grouped.length,
          itemBuilder: (context, index) {
            final dateKey = grouped.keys.elementAt(index);
            final items = grouped[dateKey]!;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DateHeader(date: dateKey),
                ...items.map((p) => PomodoroTile(pomodoro: p)),
              ],
            );
          },
        );
      },
    );
  }
}

/// 内部组件: 日期标题
class _DateHeader extends StatelessWidget {
  final DateTime date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    String text;
    if (date == today) {
      text = '今天';
    } else if (date == yesterday) {
      text = '昨天';
    } else {
      text = DateFormat('MM月dd日').format(date);
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

/// 内部组件: 空状态占位
class _EmptyStatePlaceholder extends StatelessWidget {
  const _EmptyStatePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.hourglass_empty_rounded,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            '暂无专注记录',
            style: TextStyle(color: Colors.grey.shade500, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '点击右下角按钮开始',
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
          const SizedBox(height: 100), // 视觉居中偏上一点
        ],
      ),
    );
  }
}
