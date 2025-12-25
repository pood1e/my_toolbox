import 'package:app_core/di.dart';
import 'package:data_api/data_api.dart';
import 'package:drift/drift.dart';

import 'domain/drift_storage_definition.dart';
import 'domain/kv_storage_definition.dart';
import 'service/service_providers.dart';

class DataApiOverride {
  DataApiOverride._();

  static StorageDefinition<KVStore> kvStorageDefinition(Ref ref, String name) {
    return KvStorageDefinition(instance: name);
  }

  static StorageDefinition<T> dbStorageDefinition<T extends GeneratedDatabase>(
    Ref ref,
    DatabaseId<T> dbId,
  ) {
    return DriftStorageDefinition(instance: dbId.name, factory: dbId.factory);
  }

  static Future<KVStore> globalKvStore(Ref ref, String name) async {
    final scope = await ref.watch(globalDataScopeProvider.future);
    final definition = ref.read(kvStorageDefinitionProvider(name));
    final store = scope.get(definition);
    ref.onDispose(() => scope.dispose(definition));
    return store;
  }

  static Future<KVStore> userKvStore(Ref ref, String name) async {
    final scope = await ref.watch(currentUserDataScopeProvider.future);
    final definition = ref.read(kvStorageDefinitionProvider(name));
    final store = scope.get(definition);
    ref.onDispose(() => scope.dispose(definition));
    return store;
  }

  static Future<T> globalDbStore<T extends GeneratedDatabase>(
    Ref ref,
    DatabaseId<T> dbId,
  ) async {
    final scope = await ref.watch(globalDataScopeProvider.future);
    final definition = ref.read(dbStorageDefinitionProvider(dbId));
    final store = await scope.get(definition);
    ref.onDispose(() => scope.dispose(definition));
    return store;
  }

  static Future<T> userDbStore<T extends GeneratedDatabase>(
    Ref ref,
    DatabaseId<T> dbId,
  ) async {
    final scope = await ref.watch(currentUserDataScopeProvider.future);
    final definition = ref.read(dbStorageDefinitionProvider(dbId));
    final store = await scope.get(definition);
    ref.onDispose(() => scope.dispose(definition));
    return store;
  }
}
