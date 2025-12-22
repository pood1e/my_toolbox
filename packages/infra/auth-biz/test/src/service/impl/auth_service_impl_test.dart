// test/service/auth_service_impl_test.dart
import 'package:auth_biz/auth_biz.dart';
import 'package:auth_biz/src/data/interfaces/auth_response.dart';
import 'package:auth_biz/src/service/impl/auth_service_impl.dart';
import 'package:core/http.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helper.mocks.dart';

void main() {
  late MockAuthRemoteApi mockApi;
  late MockAuthSessionStorage mockStorage;
  late AuthServiceImpl authService;

  // Test Data
  const tServer = RemoteServer(host: 'api.test', port: 443, tls: true);
  const tAuthRes = AuthResponse(
    accessToken: 'acc_token',
    refreshToken: 'ref_token',
    userId: 'u_1',
    role: 'admin',
  );

  setUp(() {
    mockApi = MockAuthRemoteApi();
    mockStorage = MockAuthSessionStorage();
  });

  // Helper to build service quickly with injected hooks
  AuthServiceImpl buildService({
    List<BeforeLogin> beforeLogins = const [],
    List<AfterLogin> afterLogins = const [],
    List<BeforeLogout> beforeLogouts = const [],
    List<AfterLogout> afterLogouts = const [],
    Function(AuthResponse, RemoteServer)? onUpdate,
    Function()? onClear,
  }) {
    return AuthServiceImpl(
      api: mockApi,
      storage: mockStorage,
      beforeLogins: beforeLogins,
      afterLogins: afterLogins,
      beforeLogouts: beforeLogouts,
      afterLogouts: afterLogouts,
      onAuthUpdate: onUpdate ?? (_, _) {},
      onAuthClear: onClear ?? () {},
    );
  }

  group('AuthService - Login Sequence', () {
    test(
      'Login Success: API -> BeforeHooks(with API Data) -> Storage -> Callback',
      () async {
        // Arrange
        bool beforeHookCalled = false;
        bool afterHookCalled = false;

        authService = buildService(
          beforeLogins: [
            (ctx) async {
              // 关键修正：验证 Hook 是在 API 之后执行的
              // Hook 收到的 Context 必须包含 API 返回的 userId ('u_1')
              expect(ctx.userId, equals(tAuthRes.userId));
              expect(ctx.server, equals(tServer));

              beforeHookCalled = true;
              return true; // 允许继续
            },
          ],
          afterLogins: [(ctx) async => afterHookCalled = true],
          onUpdate: (res, _) => expect(res, tAuthRes),
        );

        // Stub API 返回成功数据
        when(
          mockApi.login(
            server: anyNamed('server'),
            email: anyNamed('email'),
            pass: anyNamed('pass'),
          ),
        ).thenAnswer((_) async => tAuthRes);

        // Act
        await authService.login(
          host: 'api.test',
          port: 443,
          tls: true,
          email: 'e',
          pass: 'p',
        );

        // Assert
        // 1. 验证调用顺序：先 API，后存 Session
        verifyInOrder([
          mockApi.login(server: tServer, email: 'e', pass: 'p'),
          mockStorage.saveSession(authResponse: tAuthRes, server: tServer),
        ]);

        // 2. 验证 Hook 被正确触发
        expect(beforeHookCalled, true, reason: 'Before Hook 应该被调用');
        expect(afterHookCalled, true, reason: 'After Hook 应该被调用');
      },
    );

    test(
      'Login API Failure: API failed -> interceptor should not execute',
      () async {
        bool beforeHookCalled = false;
        authService = buildService(
          beforeLogins: [
            (ctx) async {
              beforeHookCalled = true;
              return true;
            },
          ],
        );

        // Stub API 抛出 401
        when(
          mockApi.login(
            server: anyNamed('server'),
            email: anyNamed('email'),
            pass: anyNamed('pass'),
          ),
        ).thenThrow(
          DioException(
            requestOptions: RequestOptions(),
            response: Response(
              requestOptions: RequestOptions(),
              statusCode: 401,
            ),
          ),
        );

        // Act & Assert
        await expectLater(
          () => authService.login(
            host: 'h',
            port: 1,
            tls: false,
            email: 'e',
            pass: 'p',
          ),
          throwsA(isA<InvalidCredentialsException>()),
        );

        // 验证：因为 API 挂了，所以 Hook 根本不该走到
        expect(beforeHookCalled, false, reason: 'API 失败后不应执行拦截器');
        // 验证：当然也不应该保存 Session
        verifyNever(
          mockStorage.saveSession(
            authResponse: anyNamed('authResponse'),
            server: anyNamed('server'),
          ),
        );
      },
    );

    test(
      'Hook Interception: API  -> interceptor return false -> abort save',
      () async {
        authService = buildService(
          beforeLogins: [
            (ctx) async {
              // 模拟拦截器拒绝登录 (例如检测到设备不兼容)
              return false;
            },
          ],
        );

        when(
          mockApi.login(
            server: anyNamed('server'),
            email: anyNamed('email'),
            pass: anyNamed('pass'),
          ),
        ).thenAnswer((_) async => tAuthRes);

        // Act & Assert
        await expectLater(
          () => authService.login(
            host: 'h',
            port: 1,
            tls: false,
            email: 'e',
            pass: 'p',
          ),
          throwsA(isA<Exception>()), // Login aborted
        );

        // 验证：API 确实被调用了
        verify(
          mockApi.login(
            server: anyNamed('server'),
            email: anyNamed('email'),
            pass: anyNamed('pass'),
          ),
        ).called(1);

        // 验证：但是 Storage 没有保存
        verifyNever(
          mockStorage.saveSession(
            authResponse: anyNamed('authResponse'),
            server: anyNamed('server'),
          ),
        );
      },
    );
  });

  group('AuthService - Logout', () {
    test('Logout Flow: Should clear local session even if API fails', () async {
      bool onClearCalled = false;
      authService = buildService(onClear: () => onClearCalled = true);

      // Mock local data existence
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(mockStorage.getUserId()).thenAnswer((_) async => 'uid');

      // Mock API failure
      when(
        mockApi.logout(
          server: anyNamed('server'),
          refreshToken: anyNamed('refreshToken'),
        ),
      ).thenThrow(Exception('Network Error'));

      await authService.logout();

      // Verify logic
      verify(mockApi.logout(server: tServer, refreshToken: 'ref')).called(1);
      verify(mockStorage.clearSession()).called(1);
      expect(onClearCalled, true);
    });

    test(
      'Logout: Should return early if local params are missing (no API call, no clear)',
      () async {
        authService = buildService();
        // Mock missing data
        when(mockStorage.getServer()).thenAnswer((_) async => null);

        await authService.logout();

        verifyNever(
          mockApi.logout(
            server: anyNamed('server'),
            refreshToken: anyNamed('refreshToken'),
          ),
        );
        // Note: Based on current logic, it returns early if null, so clearSession in finally block (if any) might depend on implementation details.
        // Assuming the implementation checks for nulls before try-finally block:
        verifyNever(mockStorage.clearSession());
      },
    );
  });
}
