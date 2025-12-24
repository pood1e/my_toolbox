// test/service/token_service_impl_test.dart
import 'package:app_core/http.dart';
import 'package:auth_api/auth_api.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:auth_biz/src/data/interfaces/auth_response.dart';
import 'package:auth_biz/src/domain/auth_exceptions.dart';
import 'package:auth_biz/src/service/impl/token_service_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../../helper.mocks.dart';

void main() {
  late MockTokenRemoteApi mockApi;
  late MockAuthSessionStorage mockStorage;
  late MockConnectionAvailabiltyNotifier mockNotifier;
  late TokenServiceImpl tokenService;

  const tServer = RemoteServer(host: 'api.test', port: 80, tls: false);
  const tAuthRes = AuthResponse(
    accessToken: 'new_acc',
    refreshToken: 'new_ref',
    userId: 'u',
    role: 'r',
  );

  setUp(() {
    mockApi = MockTokenRemoteApi();
    mockStorage = MockAuthSessionStorage();
    mockNotifier = MockConnectionAvailabiltyNotifier();

    tokenService = TokenServiceImpl(
      api: mockApi,
      storage: mockStorage,
      notifier: mockNotifier,
      onAuthUpdate: (r, s) {},
    );
  });

  group('TokenService - Check Validation', () {
    test('Not Logged In (Missing Token/Server) -> Guest & Throw', () async {
      when(mockStorage.getAccessToken()).thenAnswer((_) async => null);

      await expectLater(
        tokenService.checkTokenValidation(),
        throwsA(isA<UnknownAuthException>()),
      );

      verify(mockNotifier.save(ConnectionAvailability.guest)).called(1);
    });

    test('Check Success -> Active', () async {
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'acc');
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);

      // API check success
      when(
        mockApi.check(server: tServer, accessToken: 'acc'),
      ).thenAnswer((_) async {});

      await tokenService.checkTokenValidation();

      verify(mockNotifier.save(ConnectionAvailability.active)).called(1);
    });

    test('Check 401 -> Automatically trigger Refresh', () async {
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'old_acc');
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);

      // 1. check throws 401
      when(mockApi.check(server: tServer, accessToken: 'old_acc')).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          response: Response(requestOptions: RequestOptions(), statusCode: 401),
        ),
      );

      // 2. refresh succeeds
      when(
        mockApi.refresh(server: tServer, refreshToken: 'ref'),
      ).thenAnswer((_) async => tAuthRes);

      await tokenService.checkTokenValidation();

      // Verify refresh was called
      verify(mockApi.refresh(server: tServer, refreshToken: 'ref')).called(1);
      verify(mockNotifier.save(ConnectionAvailability.active)).called(1);
    });

    test('Check Network Error -> Offline & Throw', () async {
      when(mockStorage.getAccessToken()).thenAnswer((_) async => 'acc');
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);

      when(
        mockApi.check(
          server: anyNamed('server'),
          accessToken: anyNamed('accessToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(),
          type: DioExceptionType.connectionError,
        ),
      );

      await expectLater(
        tokenService.checkTokenValidation(),
        throwsA(isA<DioException>()),
      );

      verify(mockNotifier.save(ConnectionAvailability.offline)).called(1);
    });
  });

  group('TokenService - Refresh', () {
    test('Refresh Success -> Save Session & Active', () async {
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');

      when(
        mockApi.refresh(server: tServer, refreshToken: 'ref'),
      ).thenAnswer((_) async => tAuthRes);

      await tokenService.refresh();

      verify(
        mockStorage.saveSession(authResponse: tAuthRes, server: tServer),
      ).called(1);
      verify(mockNotifier.save(ConnectionAvailability.active)).called(1);
    });

    test('Refresh 401 -> Expired & Throw', () async {
      // 1. Mock 数据
      when(mockStorage.getServer()).thenAnswer((_) async => tServer);
      when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');

      // 2. Mock 异常
      when(
        mockApi.refresh(
          server: anyNamed('server'),
          refreshToken: anyNamed('refreshToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: ''), // Dio 5+ 建议加上 path
          response: Response(
            requestOptions: RequestOptions(path: ''),
            statusCode: 401,
          ),
        ),
      );

      // 3. 执行测试
      // 技巧：我们并发调用两次。
      // call1 是逻辑执行者，它会 rethrow 异常。
      // call2 是等待者，它会返回 _refreshCompleter.future。
      final call1 = tokenService.refresh();
      final call2 = tokenService.refresh();

      // 4. 验证
      // 必须捕获 call1 的异常 (你的原始逻辑)
      await expectLater(call1, throwsA(isA<DioException>()));

      // 必须捕获 call2 的异常 (为了防止 _refreshCompleter 报 "Uncaught Error")
      await expectLater(call2, throwsA(isA<DioException>()));

      // 验证状态更新逻辑是否执行
      verify(mockNotifier.save(ConnectionAvailability.expired)).called(1);
    });

    test(
      'Concurrency Lock: Multiple refresh calls trigger API only once',
      () async {
        when(mockStorage.getServer()).thenAnswer((_) async => tServer);
        when(mockStorage.getRefreshToken()).thenAnswer((_) async => 'ref');

        // Simulate API delay of 50ms
        when(
          mockApi.refresh(
            server: anyNamed('server'),
            refreshToken: anyNamed('refreshToken'),
          ),
        ).thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return tAuthRes;
        });

        // Fire simultaneous calls
        final f1 = tokenService.refresh();
        final f2 = tokenService.refresh();
        final f3 = tokenService.refresh();

        await Future.wait([f1, f2, f3]);

        // Core Assertion: API called only ONCE
        verify(mockApi.refresh(server: tServer, refreshToken: 'ref')).called(1);
      },
    );
  });
}
