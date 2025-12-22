import 'package:core/http.dart';
import 'package:core/object.dart';

import '../../domain/user_identity.dart';
import '../interfaces/auth_remote_api.dart';
import '../interfaces/auth_response.dart';

// 辅助方法：使用 R<T> 解析 DTO
AuthResponse _parseResponse(Map<String, dynamic> body) {
  final r = R<AuthResponse>.fromJson(
    body,
    (json) => AuthResponse.fromJson(json as Map<String, dynamic>),
  );

  if (!r.isSuccess) throw Exception(r.message); // 或 ServerException
  if (r.data == null) throw Exception('Empty data');
  return r.data!;
}

class AuthRemoteApiImpl implements AuthRemoteApi {
  final Dio _dio;

  AuthRemoteApiImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<AuthResponse> login({
    required RemoteServer server,
    required String email,
    required String pass,
  }) async {
    final response = await _dio.post(
      '${server.baseUrl}/auth/login',
      data: {'email': email, 'password': pass},
    );
    return _parseResponse(response.data);
  }

  @override
  Future<AuthResponse> register({
    required RemoteServer server,
    required String email,
    required String nickname,
    required String pass,
  }) async {
    final response = await _dio.post(
      '${server.baseUrl}/auth/register',
      data: {'email': email, 'nickname': nickname, 'password': pass},
    );
    return _parseResponse(response.data);
  }

  @override
  Future<void> logout({
    required RemoteServer server,
    required String refreshToken,
  }) async {
    try {
      await _dio.post(
        '${server.baseUrl}/auth/logout',
        data: {'refreshToken': refreshToken},
      );
    } catch (_) {
      // 登出接口忽略网络错误
    }
  }
}

class TokenRemoteApiImpl implements TokenRemoteApi {
  final Dio _dio;

  TokenRemoteApiImpl({Dio? dio})
    : _dio = dio ?? Dio(BaseOptions(connectTimeout: Duration(seconds: 5)));

  @override
  Future<AuthResponse> refresh({
    required RemoteServer server,
    required String refreshToken,
  }) async {
    final response = await _dio.post(
      '${server.baseUrl}/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    return _parseResponse(response.data);
  }

  @override
  Future<void> check({
    required RemoteServer server,
    required String accessToken,
  }) async {
    await _dio.get(
      '${server.baseUrl}/auth/check',
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }
}
