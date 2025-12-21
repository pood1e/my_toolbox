import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../data/interfaces/auth_response.dart';
import '../../domain/remote_server.dart';
import '../interfaces/auth_session_storage.dart';

class AuthSessionStorageImpl implements AuthSessionStorage {
  final FlutterSecureStorage _storage;

  const AuthSessionStorageImpl(this._storage);

  // Keys 定义为私有常量
  static const _kAccessToken = 'auth_access_token';
  static const _kRefreshToken = 'auth_refresh_token';
  static const _kUserId = 'auth_user_id';
  static const _kRole = 'auth_role';
  static const _kServer = 'auth_server_config';

  @override
  Future<void> saveSession({
    required AuthResponse authResponse,
    required RemoteServer server,
  }) async {
    await Future.wait([
      _storage.write(key: _kAccessToken, value: authResponse.accessToken),
      _storage.write(key: _kRefreshToken, value: authResponse.refreshToken),
      _storage.write(key: _kUserId, value: authResponse.userId),
      _storage.write(key: _kRole, value: authResponse.role),
      _storage.write(key: _kServer, value: jsonEncode(server.toJson())),
    ]);
  }

  @override
  Future<void> updateTokens({
    required String accessToken,
    required String refreshToken,
    String? role,
  }) async {
    final futures = <Future>[
      _storage.write(key: _kAccessToken, value: accessToken),
      _storage.write(key: _kRefreshToken, value: refreshToken),
    ];
    if (role != null) {
      futures.add(_storage.write(key: _kRole, value: role));
    }
    await Future.wait(futures);
  }

  @override
  Future<void> clearSession() async {
    await Future.wait([
      _storage.delete(key: _kAccessToken),
      _storage.delete(key: _kRefreshToken),
      _storage.delete(key: _kUserId),
      _storage.delete(key: _kRole),
      _storage.delete(key: _kServer),
    ]);
  }

  @override
  Future<String?> getAccessToken() => _storage.read(key: _kAccessToken);

  @override
  Future<String?> getRefreshToken() => _storage.read(key: _kRefreshToken);

  @override
  Future<String?> getUserId() => _storage.read(key: _kUserId);

  @override
  Future<String?> getRole() => _storage.read(key: _kRole);

  @override
  Future<RemoteServer?> getServer() async {
    final jsonStr = await _storage.read(key: _kServer);
    if (jsonStr == null || jsonStr.isEmpty) return null;
    try {
      return RemoteServer.fromJson(jsonDecode(jsonStr));
    } catch (e) {
      return null;
    }
  }
}
