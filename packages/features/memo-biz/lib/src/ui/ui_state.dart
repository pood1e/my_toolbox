import 'package:app_core/di.dart';

import '../memo_domain.dart';
import '../memo_repository.dart';

part 'ui_state.g.dart';

// 活跃笔记流
@riverpod
Stream<List<MemoDomain>> activeMemos(Ref ref) async* {
  final repo = await ref.watch(memoRepositoryProvider.future);
  yield* repo.watchMemos(isArchived: false);
}

// 归档笔记流
@riverpod
Stream<List<MemoDomain>> archivedMemos(Ref ref) async* {
  final repo = await ref.watch(memoRepositoryProvider.future);
  yield* repo.watchMemos(isArchived: true);
}
