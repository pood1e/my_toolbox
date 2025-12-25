abstract class TokenService {
  Future<void> checkTokenValidation();

  Future<void> refresh();
}
