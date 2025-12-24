import 'package:core/di.dart';
import 'package:data_biz/data_biz.dart';

import 'framework_database.dart';
import 'launcher/launcher_dao.dart';

part 'dao_providers.g.dart';

@Riverpod(keepAlive: true)
Future<FrameworkDatabase> frameworkDatabase(Ref ref) async {
  final scope = await ref.watch(currentUserDataScopeProvider.future);
  final definition = DriftStorageDefinition(
    instance: 'framework',
    factory: (e) => FrameworkDatabase(e),
  );
  final db = scope.get(definition);
  ref.onDispose(() => scope.dispose(definition));
  return db;
}

@Riverpod(keepAlive: true)
Future<LauncherDao> launcherDao(Ref ref) async {
  final db = await ref.watch(frameworkDatabaseProvider.future);
  return LauncherDao(db);
}
