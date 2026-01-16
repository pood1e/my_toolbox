import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';

import '../../pomodoro_domain.dart';
import '../components/pomodoro_fab.dart';
import '../components/pomodoro_tile.dart';
import '../state/ui_state.dart';
import 'pomodoro_screen.dart';

class PomodoroMainScreen extends ConsumerWidget {
  const PomodoroMainScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Stack(
      children: [
        // 1. 底层：基础界面 (Scaffold)
        Scaffold(
          appBar: AppBar(
            leading: const BackButton(),
            title: const Text('番茄专注'),
            centerTitle: true,
            backgroundColor: Theme.of(context).colorScheme.surface,
            scrolledUnderElevation: 0,
            actions: [
              IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
            ],
          ),
          // 历史记录列表
          body: const _HistoryListSection(),

          // 悬浮按钮 (负责新建和倒计时显示)
          // 位于 Sheet 之下。当 Sheet 展开(1.0)时，FAB 会被遮挡。
          // 当 Sheet 收起(0.0)时，FAB 可点击。
          floatingActionButton: const PomodoroFab(),
        ),

        // 2. 顶层：专注面板 (Sheet)
        // 默认高度为 0，不可见。通过 Controller 控制展开。
        const PomodoroScreen(),
      ],
    );
  }
}

// =========================================================
// 内部组件：历史列表区域
// =========================================================
class _HistoryListSection extends ConsumerWidget {
  const _HistoryListSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 获取历史列表 (已包含过滤逻辑)
    final history = ref.watch(pomodoroHistoryProvider);

    if (history.isEmpty) {
      return const _EmptyStatePlaceholder();
    }

    // 按日期分组
    final grouped = groupBy(history, (Pomodoro p) {
      final date = DateTime.fromMillisecondsSinceEpoch(p.startAt);
      return DateTime(date.year, date.month, date.day);
    });

    return ListView.builder(
      // 底部留出空间给 FAB (虽然 Sheet 是 0，但 FAB 还在)
      padding: const EdgeInsets.only(bottom: 100, top: 8),
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
  }
}

// 日期标题组件
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

// 空状态组件
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
        ],
      ),
    );
  }
}
