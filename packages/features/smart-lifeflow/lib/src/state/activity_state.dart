import 'package:app_core/di.dart';

import '../domain/reality_models.dart';
import '../service/service_providers.dart';

part 'activity_state.g.dart';

@riverpod
Stream<List<Activity>> allActivities(Ref ref) async* {
  final service = await ref.watch(activityServiceProvider.future);
  yield* service.watchAllActivities();
}
