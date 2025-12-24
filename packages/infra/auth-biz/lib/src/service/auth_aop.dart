import 'package:auth_api/auth_api.dart';

typedef BeforeLogin = Future<bool> Function(UserIdentity);
typedef AfterLogin = Future<void> Function(UserIdentity);
typedef BeforeLogout = Future<void> Function(UserIdentity);
typedef AfterLogout = Future<void> Function();
