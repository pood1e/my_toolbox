import 'package:auth_biz/src/data/remote/auth_remote_api_impl.dart';
import 'package:auth_biz/src/domain/remote_server.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http_mock_adapter/http_mock_adapter.dart';

void main() {
  late Dio dio;
  late DioAdapter dioAdapter;
  late AuthRemoteApiImpl authApi;
  late TokenRemoteApiImpl tokenApi;
  late RemoteServer testServer;

  setUp(() {
    dio = Dio(BaseOptions());
    dioAdapter = DioAdapter(dio: dio, matcher: const UrlRequestMatcher());
    authApi = AuthRemoteApiImpl(dio: dio);
    tokenApi = TokenRemoteApiImpl(dio: dio);
    testServer = const RemoteServer(host: 'example.com', port: 80, tls: false);
  });

  // Helper to create success response
  Map<String, dynamic> successResponse(Map<String, dynamic> data) {
    return {'code': 200, 'message': 'success', 'data': data};
  }

  // Helper to create error response
  Map<String, dynamic> errorResponse(int code, String message) {
    return {'code': code, 'message': message, 'data': null};
  }

  group('AuthRemoteApiImpl', () {
    group('login', () {
      test('should return AuthResponse when login succeeds', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/login';
        dioAdapter.onPost(
          url,
          (server) => server.reply(
            200,
            successResponse({
              'accessToken': 'test_access_token',
              'refreshToken': 'test_refresh_token',
              'userId': 'user_123',
              'role': 'admin',
            }),
          ),
        );

        // Act
        final result = await authApi.login(
          server: testServer,
          email: 'test@example.com',
          pass: 'password123',
        );

        // Assert
        expect(result.accessToken, 'test_access_token');
        expect(result.refreshToken, 'test_refresh_token');
        expect(result.userId, 'user_123');
        expect(result.role, 'admin');
      });

      test(
        'should throw exception when login fails with invalid credentials',
        () async {
          // Arrange
          final url = '${testServer.baseUrl}/auth/login';
          dioAdapter.onPost(
            url,
            (server) =>
                server.reply(200, errorResponse(401, 'Invalid credentials')),
          );

          // Act & Assert
          expect(
            () => authApi.login(
              server: testServer,
              email: 'test@example.com',
              pass: 'wrong_password',
            ),
            throwsA(
              isA<Exception>().having(
                (e) => e.toString(),
                'message',
                contains('Invalid credentials'),
              ),
            ),
          );
        },
      );

      test('should throw exception when response data is empty', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/login';
        dioAdapter.onPost(
          url,
          (server) => server.reply(200, {
            'code': 200,
            'message': 'success',
            'data': null,
          }),
        );

        // Act & Assert
        expect(
          () => authApi.login(
            server: testServer,
            email: 'test@example.com',
            pass: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Empty data'),
            ),
          ),
        );
      });

      test('should throw DioException when network error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/login';
        dioAdapter.onPost(
          url,
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        // Act & Assert
        expect(
          () => authApi.login(
            server: testServer,
            email: 'test@example.com',
            pass: 'password123',
          ),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw DioException when server returns 500 error', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/login';
        dioAdapter.onPost(
          url,
          (server) => server.reply(500, {'error': 'Internal server error'}),
        );

        // Act & Assert
        expect(
          () => authApi.login(
            server: testServer,
            email: 'test@example.com',
            pass: 'password123',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('register', () {
      test('should return AuthResponse when registration succeeds', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/register';
        dioAdapter.onPost(
          url,
          (server) => server.reply(
            200,
            successResponse({
              'accessToken': 'new_access_token',
              'refreshToken': 'new_refresh_token',
              'userId': 'user_456',
              'role': 'user',
            }),
          ),
        );

        // Act
        final result = await authApi.register(
          server: testServer,
          email: 'newuser@example.com',
          nickname: 'NewUser',
          pass: 'password123',
        );

        // Assert
        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
        expect(result.userId, 'user_456');
        expect(result.role, 'user');
      });

      test('should throw exception when email already exists', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/register';
        dioAdapter.onPost(
          url,
          (server) =>
              server.reply(200, errorResponse(409, 'Email already exists')),
        );

        // Act & Assert
        expect(
          () => authApi.register(
            server: testServer,
            email: 'existing@example.com',
            nickname: 'User',
            pass: 'password123',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Email already exists'),
            ),
          ),
        );
      });

      test('should throw exception when validation fails', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/register';
        dioAdapter.onPost(
          url,
          (server) =>
              server.reply(200, errorResponse(400, 'Invalid email format')),
        );

        // Act & Assert
        expect(
          () => authApi.register(
            server: testServer,
            email: 'invalid-email',
            nickname: 'User',
            pass: 'pass',
          ),
          throwsException,
        );
      });

      test('should throw DioException when network error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/register';
        dioAdapter.onPost(
          url,
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        // Act & Assert
        expect(
          () => authApi.register(
            server: testServer,
            email: 'test@example.com',
            nickname: 'User',
            pass: 'password123',
          ),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('logout', () {
      test('should complete successfully on logout', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/logout';
        dioAdapter.onPost(
          url,
          (server) => server.reply(200, {'code': 200, 'message': 'success'}),
        );

        // Act & Assert
        await expectLater(
          authApi.logout(
            server: testServer,
            refreshToken: 'test_refresh_token',
          ),
          completes,
        );
      });

      test('should not throw exception when network error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/logout';
        dioAdapter.onPost(
          url,
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          authApi.logout(
            server: testServer,
            refreshToken: 'test_refresh_token',
          ),
          completes,
        );
      });

      test('should not throw exception when server error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/logout';
        dioAdapter.onPost(
          url,
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        // Act & Assert
        await expectLater(
          authApi.logout(
            server: testServer,
            refreshToken: 'test_refresh_token',
          ),
          completes,
        );
      });

      test('should not throw exception when unauthorized', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/logout';
        dioAdapter.onPost(
          url,
          (server) => server.reply(401, {'error': 'Unauthorized'}),
        );

        // Act & Assert
        await expectLater(
          authApi.logout(server: testServer, refreshToken: 'invalid_token'),
          completes,
        );
      });
    });
  });

  group('TokenRemoteApiImpl', () {
    group('refresh', () {
      test('should return new tokens when refresh succeeds', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/refresh';
        dioAdapter.onPost(
          url,
          (server) => server.reply(
            200,
            successResponse({
              'accessToken': 'new_access_token',
              'refreshToken': 'new_refresh_token',
              'userId': 'user_123',
              'role': 'admin',
            }),
          ),
        );

        // Act
        final result = await tokenApi.refresh(
          server: testServer,
          refreshToken: 'old_refresh_token',
        );

        // Assert
        expect(result.accessToken, 'new_access_token');
        expect(result.refreshToken, 'new_refresh_token');
        expect(result.userId, 'user_123');
        expect(result.role, 'admin');
      });

      test('should throw exception when refresh token is invalid', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/refresh';
        dioAdapter.onPost(
          url,
          (server) =>
              server.reply(200, errorResponse(401, 'Invalid refresh token')),
        );

        // Act & Assert
        expect(
          () => tokenApi.refresh(
            server: testServer,
            refreshToken: 'invalid_token',
          ),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Invalid refresh token'),
            ),
          ),
        );
      });

      test('should throw exception when refresh token is expired', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/refresh';
        dioAdapter.onPost(
          url,
          (server) =>
              server.reply(200, errorResponse(401, 'Refresh token expired')),
        );

        // Act & Assert
        expect(
          () => tokenApi.refresh(
            server: testServer,
            refreshToken: 'expired_token',
          ),
          throwsException,
        );
      });

      test('should throw exception when response data is empty', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/refresh';
        dioAdapter.onPost(
          url,
          (server) => server.reply(200, {
            'code': 200,
            'message': 'success',
            'data': null,
          }),
        );

        // Act & Assert
        expect(
          () =>
              tokenApi.refresh(server: testServer, refreshToken: 'test_token'),
          throwsA(
            isA<Exception>().having(
              (e) => e.toString(),
              'message',
              contains('Empty data'),
            ),
          ),
        );
      });

      test('should throw DioException when network error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/refresh';
        dioAdapter.onPost(
          url,
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        // Act & Assert
        expect(
          () =>
              tokenApi.refresh(server: testServer, refreshToken: 'test_token'),
          throwsA(isA<DioException>()),
        );
      });
    });

    group('check', () {
      test('should complete successfully when token is valid', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/check';
        dioAdapter.onGet(
          url,
          (server) => server.reply(200, {'code': 200, 'message': 'valid'}),
        );

        // Act & Assert
        await expectLater(
          tokenApi.check(server: testServer, accessToken: 'valid_access_token'),
          completes,
        );
      });

      test('should throw DioException when token is invalid', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/check';
        dioAdapter.onGet(
          url,
          (server) => server.reply(401, {'error': 'Invalid token'}),
        );

        // Act & Assert
        expect(
          () =>
              tokenApi.check(server: testServer, accessToken: 'invalid_token'),
          throwsA(
            isA<DioException>().having(
              (e) => e.response?.statusCode,
              'status code',
              401,
            ),
          ),
        );
      });

      test('should throw DioException when token is expired', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/check';
        dioAdapter.onGet(
          url,
          (server) => server.reply(401, {'error': 'Token expired'}),
        );

        // Act & Assert
        expect(
          () =>
              tokenApi.check(server: testServer, accessToken: 'expired_token'),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw DioException when network error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/check';
        dioAdapter.onGet(
          url,
          (server) => server.throws(
            500,
            DioException(
              requestOptions: RequestOptions(path: url),
              type: DioExceptionType.connectionTimeout,
            ),
          ),
        );

        // Act & Assert
        expect(
          () => tokenApi.check(server: testServer, accessToken: 'test_token'),
          throwsA(isA<DioException>()),
        );
      });

      test('should throw DioException when server error occurs', () async {
        // Arrange
        final url = '${testServer.baseUrl}/auth/check';
        dioAdapter.onGet(
          url,
          (server) => server.reply(500, {'error': 'Server error'}),
        );

        // Act & Assert
        expect(
          () => tokenApi.check(server: testServer, accessToken: 'test_token'),
          throwsA(isA<DioException>()),
        );
      });
    });
  });
}
