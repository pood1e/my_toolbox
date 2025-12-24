import 'dart:async';

/// 存储定义
abstract class StorageDefinition<T> {
  String get key;

  Future<T> create(String path);

  Future<void> dispose(T instance);
}

abstract class Migratable<T> {
  StorageDefinition<T> get definition;

  Future<void> migrate(T source, T target);
}
