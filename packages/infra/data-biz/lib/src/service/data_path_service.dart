import 'package:auth_biz/auth_biz.dart';

abstract class DataPathService {
  String get root;
  String get guestRoot;
  String getUserRoot(String userId, RemoteServer server);
}
