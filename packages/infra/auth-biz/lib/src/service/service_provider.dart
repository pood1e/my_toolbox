import 'package:app_core/di.dart';

import '../data/local/local_storage_providers.dart';
import '../data/remote/auth_remote_api_providers.dart';
import '../domain/connection_availability.dart';
import '../need_override_providers.dart';
import '../state/auth_state_notifier.dart';
import 'auth_service.dart';
import 'impl/auth_service_impl.dart';
import 'impl/token_service_impl.dart';
import 'token_service.dart';

part 'service_provider.g.dart';

@Riverpod(keepAlive: true)
Future<TokenService> tokenService(Ref ref) async {
  final api = await ref.read(tokenRemoteApiProvider.future);
  final storage = await ref.read(authSessionStorageProvider.future);
  final notifier = ref.read(connectionAvailabiltyProvider.notifier);

  return TokenServiceImpl(
    api: api,
    storage: storage,
    notifier: notifier,
    onAuthUpdate: (response, server) {
      ref.read(remoteServerProvider.notifier).save(server);
      ref.read(accessTokenProvider.notifier).save(response.accessToken);
      ref.read(refreshTokenProvider.notifier).save(response.refreshToken);
      ref.read(userIdProvider.notifier).save(response.userId);
      ref.read(roleProvider.notifier).save(response.role);
    },
  );
}

@Riverpod(keepAlive: true)
Future<AuthService> authService(Ref ref) async {
  final api = await ref.read(authRemoteApiProvider.future);
  final storage = await ref.read(authSessionStorageProvider.future);

  return AuthServiceImpl(
    api: api,
    storage: storage,
    beforeLogins: await ref.read(beforeLoginsProvider.future),
    afterLogins: await ref.read(afterLoginsProvider.future),
    beforeLogouts: await ref.read(beforeLogoutsProvider.future),
    afterLogouts: await ref.read(afterLogoutsProvider.future),
    onAuthUpdate: (response, server) {
      ref.read(remoteServerProvider.notifier).save(server);
      ref.read(accessTokenProvider.notifier).save(response.accessToken);
      ref.read(refreshTokenProvider.notifier).save(response.refreshToken);
      ref.read(userIdProvider.notifier).save(response.userId);
      ref.read(roleProvider.notifier).save(response.role);
      ref
          .read(connectionAvailabiltyProvider.notifier)
          .save(ConnectionAvailability.active);
    },
    onAuthClear: () {
      ref.read(remoteServerProvider.notifier).clear();
      ref.read(accessTokenProvider.notifier).clear();
      ref.read(refreshTokenProvider.notifier).clear();
      ref.read(userIdProvider.notifier).clear();
      ref.read(roleProvider.notifier).clear();

      ref
          .read(connectionAvailabiltyProvider.notifier)
          .save(ConnectionAvailability.guest);
    },
  );
}
