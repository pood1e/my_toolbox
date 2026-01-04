import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';

import 'event_timeline_row.dart';
import 'timeline_view_model.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _EventScreenState();
}

class _EventScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(timelineDateListProvider.notifier).loadMoreDays(3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final dateList = ref.watch(timelineDateListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Timeline'),
        leading: BackButton(
          onPressed: () {
            context.pop();
          },
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          // 2. 遍历日期列表
          // 使用 SliverList.builder 性能更好，懒加载
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final date = dateList[index];
              // 3. 返回一个独立的 Widget 负责渲染这一天
              // 使用 const 构造函数（如果可能），配合 Provider 缓存机制
              return _DailySection(date: date);
            }, childCount: dateList.length),
          ),

          // 底部 Loading
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }
}

// --- 关键组件：每一天的区块 ---
// 这个组件必须是 ConsumerWidget，因为它要 watch 自己的数据流
class _DailySection extends ConsumerWidget {
  final DateTime date;

  const _DailySection({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 4. 这里只 watch 这一天的数据！
    // 即使 "今天" 的数据变了，"昨天" 的 Provider 也不会收到通知，
    // "昨天" 的 UI 也不会重绘。
    final asyncEvents = ref.watch(eventsForDateProvider(date));

    return asyncEvents.when(
      data: (events) {
        // 如果这一天没数据，可以选择隐藏或者显示空状态
        if (events.isEmpty) {
          // 也可以返回 SizedBox.shrink() 隐藏
          return SizedBox.shrink();
        }

        return Column(
          children: [
            // 头部：Sticky Header 效果需要配合 sticky_headers 包，或者这里简单展示
            _SimpleDateHeader(date: date),

            // 事件列表
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return EventTimelineRow(event: events[index]);
              },
            ),
          ],
        );
      },
      // 这里的 loading 只有在这一天第一次滑入屏幕加载时会出现
      loading: () => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator.adaptive()),
      ),
      error: (e, st) => Text('Error: $e'),
    );
  }
}

class _SimpleDateHeader extends StatelessWidget {
  final DateTime date;

  const _SimpleDateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      color: const Color(0xFFF5F7FA),
      alignment: Alignment.centerLeft,
      child: Text(
        DateFormat('yyyy-MM-dd').format(date),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
