import 'package:drift/drift.dart';

import '../domain/kv_store.dart';

abstract class DataScope {
  String get id;

  String get rootPath;

  KVStore getKv(String name);

  T getDatabase<T extends GeneratedDatabase>(
    T Function(QueryExecutor e) factory,
  );

  Future<void> close();

  Future<void> delete();
}
