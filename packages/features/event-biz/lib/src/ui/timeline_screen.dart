import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:flutter/material.dart';

import 'components/daily_section.dart';
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
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final date = dateList[index];
              return DailySection(date: date);
            }, childCount: dateList.length),
          ),

          // 底部 Loading
          const SliverToBoxAdapter(child: SizedBox(height: 50)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
