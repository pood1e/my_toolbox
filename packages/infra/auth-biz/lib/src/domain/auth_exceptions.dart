/// 认证模块基类异常 (Sealed: 不能直接实例化)
sealed class AuthException implements Exception {}

// --- 具体异常子类 ---

/// 1. 凭证失效 (401 - Refresh Token 也过期)
class TokenExpiredException extends AuthException {}

/// 2. 账号或密码错误 (登录失败)
class InvalidCredentialsException extends AuthException {}

/// 3. 网络不可用
class NetworkUnavailableException extends AuthException {
  final Object? originalError;

  NetworkUnavailableException([this.originalError]);
}

/// 4. 服务端返回的业务错误 (e.g. "邮箱已存在", "验证码错误")
class ServerException extends AuthException {
  final int? code;
  final String? message;

  ServerException({this.code, this.message});
}

/// 5. 未知/通用错误 (兜底)
class UnknownAuthException extends AuthException {
  final String? message;

  UnknownAuthException({this.message});

  @override
  String toString() {
    return message ?? 'UnknownAuthException';
  }
}


class AuthInterceptorException extends AuthException {
  final String? message;

  AuthInterceptorException({this.message});

  @override
  String toString() {
    return message ?? 'AuthInterceptorException';
  }
}
