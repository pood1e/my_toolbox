import 'package:auth_biz/auth_biz.dart';
import 'package:core/di.dart';
import 'package:drift/drift.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/kv_store.dart';
import '../need_override_providers.dart';
import '../scope/data_scope.dart';
import 'data_migration_service.dart';
import 'data_path_service.dart';
import 'data_scope_service.dart';
import 'impl/data_migration_service_impl.dart';
import 'impl/data_path_service_impl.dart';
import 'impl/data_scope_service_impl.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<DataPathService> dataPathService(Ref ref) async {
  final storageDirectory = await getApplicationDocumentsDirectory();
  return DataPathServiceImpl(storagePath: storageDirectory.path);
}

@Riverpod(keepAlive: true)
Future<DataScopeService> dataScopeService(Ref ref) async {
  final pathService = await ref.watch(dataPathServiceProvider.future);
  return DataScopeServiceImpl(pathService: pathService);
}

@Riverpod(keepAlive: true)
Future<DataScope> currentUserDataScope(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  // 监听用户身份变化，自动切换 Scope
  final userId = await ref.watch(currentUserIdentityProvider.future);

  if (userId != null) {
    return manager.getUserScope(userId);
  } else {
    return manager.getGuestScope();
  }
}

@riverpod
Future<KVStore> kvStorage(Ref ref, String name) async {
  final scope = await ref.watch(currentUserDataScopeProvider.future);
  return scope.getKv(name);
}

@Riverpod(keepAlive: true)
Future<DataMigrationService> dataMigration(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  final dbMigrators = ref.watch(dbMigrationRegistryProvider);
  final kvMigrators = ref.watch(kvMigrationRegistryProvider);
  final factory = ref.read(migrationDatabaseFactoryProvider);
  return DataMigrationServiceImpl(
    manager: manager,
    dbMigrators: dbMigrators,
    kvMigrators: kvMigrators,
    dbFactory: factory,
  );
}

@Riverpod(keepAlive: true)
Future<GeneratedDatabase> currentUserDatabase(Ref ref) async {
  final scope = await ref.watch(currentUserDataScopeProvider.future);
  final factory = ref.watch(migrationDatabaseFactoryProvider);
  return factory(scope);
}
