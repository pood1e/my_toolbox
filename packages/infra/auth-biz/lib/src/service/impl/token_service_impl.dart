import 'dart:async';

import 'package:core/http.dart';
import 'package:core/logger.dart';

import '../../data/interfaces/auth_remote_api.dart';
import '../../data/interfaces/auth_response.dart';
import '../../data/interfaces/auth_session_storage.dart';
import '../../domain/auth_exceptions.dart';
import '../../domain/connection_availability.dart';
import '../../domain/user_identity.dart';
import '../../state/connection_availabilty_notifier.dart';
import '../token_service.dart';

class TokenServiceImpl implements TokenService {
  final TokenRemoteApi _api;
  final AuthSessionStorage _storage;
  final ConnectionAvailabiltyNotifier _notifier;
  final void Function(AuthResponse, RemoteServer) _onAuthUpdate;
  Completer<void>? _refreshCompleter;

  TokenServiceImpl({
    required TokenRemoteApi api,
    required AuthSessionStorage storage,
    required ConnectionAvailabiltyNotifier notifier,
    required void Function(AuthResponse, RemoteServer) onAuthUpdate,
  }) : _api = api,
       _storage = storage,
       _notifier = notifier,
       _onAuthUpdate = onAuthUpdate;

  @override
  Future<void> checkTokenValidation() async {
    final accessToken = await _storage.getAccessToken();
    final refreshToken = await _storage.getRefreshToken();
    final server = await _storage.getServer();
    // 未登录
    if (accessToken == null || server == null || refreshToken == null) {
      _notifier.save(ConnectionAvailability.guest);
      throw UnknownAuthException(message: 'not found user');
    }

    try {
      // --- 阶段 A: 尝试验证现有 Access Token ---
      await _api.check(server: server, accessToken: accessToken);
      _notifier.save(ConnectionAvailability.active);
    } on DioException catch (e) {
      // --- 阶段 B: 处理 Access Token 失效 (401) ---
      if (e.response?.statusCode == 401) {
        await refresh();
      } else {
        logger.e('check error: ${e.message}', error: e);
        _notifier.save(ConnectionAvailability.offline);
        rethrow;
      }
    } catch (e) {
      logger.e('check error', error: e);
      _notifier.save(ConnectionAvailability.offline);
      rethrow;
    }
  }

  @override
  Future<void> refresh() async {
    // 1. 如果正在刷新，直接等待结果，不发起新请求
    if (_refreshCompleter != null) {
      logger.i('Token refresh already in progress, waiting...');
      return _refreshCompleter!.future;
    }
    _refreshCompleter = Completer<void>();

    try {
      final server = await _storage.getServer();
      final refreshToken = await _storage.getRefreshToken();
      if (server == null || refreshToken == null) {
        logger.e('refresh failed: server/refreshToken is null');
        _notifier.save(ConnectionAvailability.guest);
        throw UnknownAuthException(message: 'not found user');
      }
      try {
        final response = await _api.refresh(
          server: server,
          refreshToken: refreshToken,
        );
        await _storage.saveSession(authResponse: response, server: server);
        _onAuthUpdate(response, server);
        _notifier.save(ConnectionAvailability.active);
        logger.i('refresh token successfully');
      } on DioException catch (e) {
        if (e.response?.statusCode == 401) {
          // refresh token过期
          logger.i('refresh token expired');
          _notifier.save(ConnectionAvailability.expired);
        } else {
          logger.e('refresh failed: ${e.message}', error: e);
          _notifier.save(ConnectionAvailability.offline);
        }
        rethrow;
      }
      _refreshCompleter!.complete();
    } catch (e) {
      _refreshCompleter!.completeError(e);
      rethrow;
    } finally {
      // 2. 清理锁
      _refreshCompleter = null;
    }
  }
}
