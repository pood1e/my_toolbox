import 'package:app_core/di.dart';
import 'package:data_api/data_api.dart';

import 'framework_database.dart';
import 'launcher/launcher_dao.dart';

part 'dao_providers.g.dart';

@Riverpod(keepAlive: true)
Future<FrameworkDatabase> frameworkDatabase(Ref ref) async {
  return await ref.watch(
    userDbStoreProvider(
      DatabaseId('framework', (e) => FrameworkDatabase(e)),
    ).future,
  );
}

@Riverpod(keepAlive: true)
Future<LauncherDao> launcherDao(Ref ref) async {
  final db = await ref.watch(frameworkDatabaseProvider.future);
  return LauncherDao(db);
}
