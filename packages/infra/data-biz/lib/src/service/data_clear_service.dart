import 'package:auth_biz/auth_biz.dart';

abstract class DataClearService {
  Future<void> clearGuest();
  Future<void> clearUser(String userId, RemoteServer server);
}