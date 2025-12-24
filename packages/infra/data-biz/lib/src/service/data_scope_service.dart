import 'package:data_api/data_api.dart';

abstract class DataScopeService {
  Future<DataScope> get(String id);

  Future<void> close(String id);

  Future<void> delete(String id);
}
