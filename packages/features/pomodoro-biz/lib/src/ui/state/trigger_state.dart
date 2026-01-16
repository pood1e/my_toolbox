import 'package:app_core/di.dart';

import '../../pomodoro_domain.dart';
import '../../providers.dart';

part 'trigger_state.g.dart';

@riverpod
Stream<Pomodoro?> latestPomodoro(Ref ref) async* {
  final service = await ref.watch(pomodoroServiceProvider.future);
  yield* service.watchLatest();
}

@riverpod
Stream<int> ticker(Ref ref) {
  return Stream.periodic(
    const Duration(seconds: 1),
    (_) => DateTime.now().millisecondsSinceEpoch,
  );
}
