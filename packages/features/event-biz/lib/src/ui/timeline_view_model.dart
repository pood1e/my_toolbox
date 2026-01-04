import 'package:app_core/di.dart';
import 'package:event_api/event_api.dart';

import '../repository/repository_providers.dart';

part 'timeline_view_model.g.dart';

@riverpod
class TimelineDateList extends _$TimelineDateList {
  @override
  List<DateTime> build() {
    // 初始状态：加载今天
    final now = DateTime.now();
    return List.generate(3, (index) {
      return DateTime(now.year, now.month, now.day).subtract(Duration(days: index));
    });
  }

  void loadMoreDays(int count) {
    // 取出列表中最后一天
    final lastDate = state.last;

    // 生成接下来的几天
    final newDates = List.generate(count, (index) {
      return lastDate.subtract(Duration(days: index + 1));
    });

    // 追加到列表末尾
    // 这一步只会触发 UI 列表长度的变化，不会导致旧的 Item 重绘
    state = [...state, ...newDates];
  }
}

@riverpod
Stream<List<Event>> eventsForDate(Ref ref, DateTime date) async* {
  final repo = await ref.watch(eventRepositoryProvider.future);
  final startMs = date.millisecondsSinceEpoch;
  final endMs = date
      .add(const Duration(days: 1))
      .subtract(const Duration(milliseconds: 1))
      .millisecondsSinceEpoch;
  yield* repo.watchByRange(startMs, endMs);
}
