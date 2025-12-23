import '../domain/data_source.dart';

abstract class DataScope {
  Future<T> get<T>(StorageDefinition<T> source);

  Future<void> dispose(StorageDefinition<dynamic> source);

  Future<void> close();

  Future<void> delete();
}
