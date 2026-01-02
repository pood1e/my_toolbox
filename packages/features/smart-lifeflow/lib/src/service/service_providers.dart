import 'package:app_core/di.dart';

import '../repository/repository_providers.dart';
import 'impl/activity_service_impl.dart';
import 'reality_services.dart';

part 'service_providers.g.dart';

@riverpod
Future<ActivityService> activityService(Ref ref) async {
  return ActivityServiceImpl(
    activityRepo: await ref.watch(activityRepositoryProvider.future),
  );
}
