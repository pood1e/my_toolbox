import 'package:auth_biz/auth_biz.dart';

import '../scope/data_scope.dart';

abstract class DataScopeService {
  Future<DataScope> getGuestScope();

  Future<DataScope> getUserScope(UserIdentity user);

  Future<void> closeScope(String id);
}
