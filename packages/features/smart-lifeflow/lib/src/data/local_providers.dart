import 'package:app_core/di.dart';
import 'package:framework_api/framework_api.dart';

import 'daos/reality_daos.dart';
import 'lifeflow_database.dart';

part 'local_providers.g.dart';

@riverpod
Future<LifeflowDatabase> lifeflowDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(
      DatabaseId('lifeflow', (e) => LifeflowDatabase(e)),
    ).future,
  );
}

@riverpod
Future<ActivityDao> activityDao(Ref ref) async {
  final db = await ref.watch(lifeflowDatabaseProvider.future);
  return db.activityDao;
}
