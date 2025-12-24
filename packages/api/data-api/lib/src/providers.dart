import 'package:app_core/di.dart';
import 'package:app_core/object.dart';
import 'package:drift/drift.dart';

import 'domain/kv_store.dart';
import 'domain/storage_definition.dart';

part 'providers.g.dart';

typedef DatabaseFactory<T extends GeneratedDatabase> =
    T Function(QueryExecutor);

class DatabaseId<T extends GeneratedDatabase> {
  final String name;
  final DatabaseFactory<T> factory;

  const DatabaseId(this.name, this.factory);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DatabaseId<T> &&
          runtimeType == other.runtimeType &&
          name == other.name;

  @override
  int get hashCode => name.hashCode;
}

@riverpod
StorageDefinition<KVStore> kvStorageDefinition(Ref ref, String name) {
  throw NotOverrideError();
}

@riverpod
StorageDefinition<T> dbStorageDefinition<T extends GeneratedDatabase>(
  Ref ref,
  DatabaseId<T> dbId,
) {
  throw NotOverrideError();
}

@riverpod
Future<KVStore> globalKvStore(Ref ref, String name) async {
  throw NotOverrideError();
}

@riverpod
Future<T> globalDbStore<T extends GeneratedDatabase>(
  Ref ref,
  DatabaseId<T> dbId,
) async {
  throw NotOverrideError();
}

@riverpod
Future<KVStore> userKvStore(Ref ref, String name) async {
  throw NotOverrideError();
}

@riverpod
Future<T> userDbStore<T extends GeneratedDatabase>(
  Ref ref,
  DatabaseId<T> dbId,
) async {
  throw NotOverrideError();
}
