import 'storage_definition.dart';

abstract class DataScope {
  Future<T> get<T>(StorageDefinition<T> source);

  Future<void> dispose(StorageDefinition<dynamic> source);

  Future<void> close();

  Future<void> delete();
}
