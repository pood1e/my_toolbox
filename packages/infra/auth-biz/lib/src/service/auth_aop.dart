import '../domain/user_identity.dart';

typedef BeforeLogin = Future<bool> Function(UserIdentity);
typedef AfterLogin = Future<void> Function(UserIdentity);
typedef BeforeLogout = Future<void> Function(UserIdentity);
typedef AfterLogout = Future<void> Function();
