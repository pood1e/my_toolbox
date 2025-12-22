import 'package:core/di.dart';
import 'package:core/http.dart';
import 'package:core/logger.dart';

import '../domain/connection_availability.dart';
import '../state/auth_state_notifier.dart';
import '../state/connection_availabilty_notifier.dart';
import '../service/service_provider.dart';
import 'auth_interceptor.dart';

part 'authenciated_dio_provider.g.dart';

@Riverpod(keepAlive: true)
Future<Dio> authenticatedDio(Ref ref) async {
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

@Riverpod(keepAlive: true)
Future<String?> authenciatedAccessToken(Ref ref) async {
  final availability = ref.watch(connectionAvailabiltyProvider);
  if (availability != ConnectionAvailability.active) {
    return null;
  }
  return await ref.watch(accessTokenProvider.future);
}
