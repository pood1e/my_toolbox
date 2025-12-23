import '../scope/data_scope.dart';

abstract class DataScopeService {
  Future<DataScope> get(String id);

  Future<void> close(String id);
}
