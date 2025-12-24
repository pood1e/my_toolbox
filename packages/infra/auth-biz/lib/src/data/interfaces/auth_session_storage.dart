import 'package:auth_api/auth_api.dart';

import 'auth_response.dart';

/// 本地认证数据源接口
/// 负责管理 Token、用户信息、服务器配置的持久化
abstract class AuthSessionStorage {
  /// 保存完整的会话信息 (登录/注册成功时)
  Future<void> saveSession({
    required AuthResponse authResponse,
    required RemoteServer server,
  });

  /// 仅更新 Token (刷新 Token 成功时)
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  });

  /// 清除所有会话信息 (登出时)
  Future<void> clearSession();

  // --- 读取方法 ---

  Future<String?> getAccessToken();

  Future<String?> getRefreshToken();

  Future<String?> getUserId();

  Future<String?> getRole();

  Future<RemoteServer?> getServer();
}
