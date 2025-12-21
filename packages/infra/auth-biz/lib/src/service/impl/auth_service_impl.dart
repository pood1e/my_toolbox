import 'package:core/logger.dart';
import 'package:dio/dio.dart';

import '../../data/interfaces/auth_remote_api.dart';
import '../../data/interfaces/auth_response.dart';
import '../../data/interfaces/auth_session_storage.dart';
import '../../domain/auth_exceptions.dart';
import '../../domain/user_identity.dart';
import '../auth_aop.dart';
import '../auth_service.dart';

class AuthServiceImpl implements AuthService {
  final AuthRemoteApi _api;
  final AuthSessionStorage _storage;
  final List<BeforeLogin> _beforeLogins;
  final List<AfterLogin> _afterLogins;
  final List<BeforeLogout> _beforeLogouts;
  final List<AfterLogout> _afterLogouts;

  final void Function(AuthResponse, RemoteServer) _onAuthUpdate;
  final void Function() _onAuthClear;

  AuthServiceImpl({
    required AuthRemoteApi api,
    required AuthSessionStorage storage,
    required List<BeforeLogin> beforeLogins,
    required List<AfterLogin> afterLogins,
    required List<BeforeLogout> beforeLogouts,
    required List<AfterLogout> afterLogouts,
    required void Function(AuthResponse, RemoteServer) onAuthUpdate,
    required void Function() onAuthClear,
  }) : _api = api,
       _storage = storage,
       _beforeLogins = beforeLogins,
       _afterLogins = afterLogins,
       _beforeLogouts = beforeLogouts,
       _afterLogouts = afterLogouts,
       _onAuthUpdate = onAuthUpdate,
       _onAuthClear = onAuthClear;

  @override
  Future<void> login({
    required String host,
    required int port,
    required bool tls,
    required String email,
    required String pass,
  }) async {
    final server = RemoteServer(host: host, port: port, tls: tls);
    try {
      final AuthResponse response = await _api.login(
        server: server,
        email: email,
        pass: pass,
      );
      await _aroundLogin(server, response);
    } on DioException catch (e) {
      // 账号密码错误
      if (e.response?.statusCode == 401) {
        throw InvalidCredentialsException();
      }
      throw _handleDioException(e);
    }
  }

  @override
  Future<void> logout() async {
    final server = await _storage.getServer();
    final refreshToken = await _storage.getRefreshToken();
    final userId = await _storage.getUserId();
    if (server == null || refreshToken == null || userId == null) {
      return;
    }
    final ctx = UserIdentity(userId: userId, server: server);
    await Future.wait(_beforeLogouts.map((hook) => hook(ctx)));
    try {
      await _api.logout(server: server, refreshToken: refreshToken);
    } catch (e) {
      logger.e('logout request failed: $e', error: e);
    } finally {
      await _storage.clearSession();
      _onAuthClear();
    }
    await Future.wait(_afterLogouts.map((hook) => hook()));
  }

  @override
  Future<void> register({
    required String host,
    required int port,
    required bool tls,
    required String email,
    required String pass,
    required String nickname,
  }) async {
    final server = RemoteServer(host: host, port: port, tls: tls);
    try {
      // 1. 获取session
      final AuthResponse response = await _api.register(
        server: server,
        email: email,
        pass: pass,
        nickname: nickname,
      );
      await _aroundLogin(server, response);
    } on DioException catch (e) {
      _handleDioException(e);
    }
  }

  Future<void> _aroundLogin(RemoteServer server, AuthResponse response) async {
    final ctx = UserIdentity(userId: response.userId, server: server);
    for (final hook in _beforeLogins) {
      if (!await hook(ctx)) throw Exception('Login aborted');
    }

    await _storage.saveSession(authResponse: response, server: server);
    _onAuthUpdate(response, server);

    await Future.wait(_afterLogins.map((hook) => hook(ctx)));
    logger.i('login successfully');
  }

  Exception _handleDioException(DioException e) {
    // 2. 处理网络层错误
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      return NetworkUnavailableException(e);
    }

    // 3. 处理服务端返回的明确错误信息
    // 假设后端返回结构: { "code": 400, "message": "邮箱已存在", ... }
    if (e.response != null && e.response!.data is Map) {
      final data = e.response!.data as Map<String, dynamic>;
      if (data.containsKey('message')) {
        return ServerException(
          code: e.response?.statusCode,
          message: data['message'],
        );
      }
    }

    // 4. 兜底未知错误 (使用具体的 UnknownAuthException)
    return UnknownAuthException(message: e.message);
  }
}
