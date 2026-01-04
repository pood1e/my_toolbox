import 'package:app_core/di.dart';
import 'package:app_core/utils.dart';
import 'package:flutter/material.dart';

import '../timeline_view_model.dart';
import 'event_timeline_row.dart';

class DailySection extends ConsumerWidget {
  final DateTime date; // ✅ 渲染头部全靠它

  const DailySection({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncEvents = ref.watch(eventsForDateProvider(date));

    return asyncEvents.when(
      data: (events) {
        if (events.isEmpty) {
          return _SimpleDateHeader(date: date);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SimpleDateHeader(date: date),
            Column(
              children: events.map((event) {
                return EventTimelineRow(event: event);
              }).toList(),
            ),
          ],
        );
      },
      // 给 Loading 一个固定高度，防止高度为0
      loading: () => const SizedBox(
        height: 60,
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
      alignment: Alignment.centerLeft,
      child: Text(
        DateFormat('yyyy-MM-dd').format(date),
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
      ),
    );
  }
}
