import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import '../data/local_providers.dart';
import 'impl/activity_repository_impl.dart';
import 'reality_repositories.dart';

part 'repository_providers.g.dart';

@riverpod
Future<ActivityRepository> activityRepository(Ref ref) async {
  return ActivityRepositoryImpl(
    dao: await ref.watch(activityDaoProvider.future),
    timeService: await ref.watch(serverTimeServiceProvider.future),
  );
}
