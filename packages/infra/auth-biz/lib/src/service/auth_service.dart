abstract class AuthService {
  Future<void> login({
    required String host,
    required int port,
    required bool tls,
    required String email,
    required String pass,
  });

  Future<void> register({
    required String host,
    required int port,
    required bool tls,
    required String email,
    required String pass,
    required String nickname,
  });

  Future<void> logout();
}
