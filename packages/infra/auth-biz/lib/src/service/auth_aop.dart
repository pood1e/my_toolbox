import 'package:core/object.dart';

import '../domain/remote_server.dart';

part 'auth_aop.freezed.dart';

@freezed
abstract class AuthContext with _$AuthContext {
  const factory AuthContext({
    required String userId,
    required RemoteServer server,
  }) = _AuthContext;
}

typedef BeforeLogin = Future<bool> Function(AuthContext ctx);
typedef AfterLogin = Future<void> Function(AuthContext ctx);
typedef BeforeLogout = Future<void> Function(AuthContext ctx);
typedef AfterLogout = Future<void> Function();
