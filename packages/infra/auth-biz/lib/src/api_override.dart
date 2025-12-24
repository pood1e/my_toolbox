/// api的接口覆盖
library;

import 'package:app_core/di.dart';
import 'package:app_core/http.dart';
import 'package:app_core/logger.dart';
import 'package:auth_api/auth_api.dart';

import 'network/auth_interceptor.dart';
import 'service/service_provider.dart';
import 'state/auth_state_notifier.dart';

class AuthApiOverride {
  AuthApiOverride._();

  static Future<UserIdentity?> currentUserIdentity(Ref ref) async {
    final server = await ref.watch(remoteServerProvider.future);
    final userId = await ref.watch(userIdProvider.future);
    if (server == null || userId == null) {
      return null;
    }
    return UserIdentity(userId: userId, server: server);
  }

  static Future<Dio> authenticatedDio(Ref ref) async {
    // 如果想切换server时使用新的dio
    // await ref.watch(remoteServerProvider.future);
    final dio = Dio();
    dio.interceptors.add(
      AuthInterceptor(
        accessGetter: () async {
          final token = await ref.read(accessTokenProvider.future);
          if (token == null) {
            logger.e('accessToken is empty, request should not send now');
            throw Exception();
          }
          return token;
        },
        baseUrlGetter: () async {
          final server = await ref.read(remoteServerProvider.future);
          if (server == null) {
            logger.e('server is empty, request should not send now');
            throw Exception();
          }
          return server.baseUrl;
        },
        refresh: () async {
          final service = await ref.read(tokenServiceProvider.future);
          await service.refresh();
        },
      ),
    );
    return dio;
  }
}
