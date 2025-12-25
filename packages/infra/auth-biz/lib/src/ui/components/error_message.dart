import '../../domain/auth_exceptions.dart';

/// 统一错误处理工具
String getAuthErrorMessage(Object error) {
  switch (error) {
    case InvalidCredentialsException():
      return '账号或密码错误';
    case NetworkUnavailableException():
      return '服务器连接失败';
    case ServerException():
      return error.message ?? '服务器拒绝请求 (Code: ${error.code})';
    case TokenExpiredException():
      return '认证已过期，请重新登陆';
    case UnknownAuthException():
      return error.message ?? '发生未知错误';
    case AuthInterceptorException():
      return error.message ?? '登陆拦截';
  }
  return error.toString();
}
