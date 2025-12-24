import 'package:auth_biz/auth_biz.dart';
import 'package:core/di.dart';
import 'package:path_provider/path_provider.dart';

import '../domain/kv_store.dart';
import '../domain/scope_type.dart';
import '../need_override_providers.dart';
import '../scope/data_scope.dart';
import '../sources/kv_storage_definition.dart';
import 'data_migration_service.dart';
import 'data_scope_service.dart';
import 'impl/data_migration_service_impl.dart';
import 'impl/data_scope_service_impl.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
Future<DataScopeService> dataScopeService(Ref ref) async {
  final storageDirectory = await getApplicationDocumentsDirectory();
  return DataScopeServiceImpl(root: storageDirectory.path);
}

@Riverpod(keepAlive: true)
Future<DataScope> globalDataScope(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  return manager.get(GlobalScope().id);
}

@Riverpod(keepAlive: true)
Future<DataScope> currentUserDataScope(Ref ref) async {
  final manager = await ref.watch(dataScopeServiceProvider.future);
  // 监听用户身份变化，自动切换 Scope
  final userId = await ref.watch(currentUserIdentityProvider.future);
  final scopeId = userId == null ? GuestScope() : UserScope(identity: userId);
  return manager.get(scopeId.id);
}

@Riverpod(keepAlive: true)
Future<DataMigrationService> dataMigration(Ref ref) async {
  final service = await ref.watch(dataScopeServiceProvider.future);
  final migrations = ref.watch(migrationsProvider);
  return DataMigrationServiceImpl(
    migrations: migrations,
    scopeService: service,
  );
}

@riverpod
Future<KVStore> userKvStore(Ref ref, String name) async {
  final scope = await ref.watch(currentUserDataScopeProvider.future);
  final kvDataDefintion = KvStorageDefinition(instance: name);
  final store = scope.get(kvDataDefintion);
  ref.onDispose(() => scope.dispose(kvDataDefintion));
  return store;
}
