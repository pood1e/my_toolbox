import 'package:auth_api/auth_api.dart';

import 'auth_response.dart';

/// 鉴权api
abstract class AuthRemoteApi {
  Future<AuthResponse> login({
    required RemoteServer server,
    required String email,
    required String pass,
  });

  Future<AuthResponse> register({
    required RemoteServer server,
    required String email,
    required String nickname,
    required String pass,
  });

  Future<void> logout({
    required RemoteServer server,
    required String refreshToken,
  });
}

/// token api
abstract class TokenRemoteApi {
  Future<AuthResponse> refresh({
    required RemoteServer server,
    required String refreshToken,
  });

  Future<void> check({
    required RemoteServer server,
    required String accessToken,
  });
}
