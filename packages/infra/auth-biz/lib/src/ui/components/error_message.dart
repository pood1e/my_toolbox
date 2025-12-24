import '../../domain/auth_exceptions.dart';

/// 统一错误处理工具
String getAuthErrorMessage(Object error) {
  if (error is InvalidCredentialsException) {
    return '账号或密码错误';
  } else if (error is NetworkUnavailableException) {
    return '服务器连接失败';
  } else if (error is ServerException) {
    return error.message ?? '服务器拒绝请求 (Code: ${error.code})';
  } else if (error is TokenExpiredException) {
    return '认证已过期，请重新登陆';
  } else if (error is UnknownAuthException) {
    return error.message ?? '发生未知错误';
  }
  return error.toString();
}
