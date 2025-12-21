import 'package:core/di.dart';

import '../interfaces/auth_remote_api.dart';
import 'auth_remote_api_impl.dart';

part 'auth_remote_api_providers.g.dart';

@Riverpod(keepAlive: true)
Future<AuthRemoteApi> authRemoteApi(Ref ref) async {
  return AuthRemoteApiImpl();
}

@Riverpod(keepAlive: true)
Future<TokenRemoteApi> tokenRemoteApi(Ref ref) async {
  return TokenRemoteApiImpl();
}
