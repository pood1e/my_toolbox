import 'package:app_core/di.dart';

import 'domain/user_identity.dart';
import 'service/auth_aop.dart';
import 'state/auth_state_notifier.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<UserIdentity?> currentUserIdentity(Ref ref) async {
  final server = await ref.watch(remoteServerProvider.future);
  final userId = await ref.watch(userIdProvider.future);
  if (server == null || userId == null) {
    return null;
  }
  return UserIdentity(userId: userId, server: server);
}

@Riverpod(keepAlive: true)
Future<List<BeforeLogin>> beforeLogins(Ref ref) async {
  return [];
}

@Riverpod(keepAlive: true)
Future<List<AfterLogin>> afterLogins(Ref ref) async {
  return [];
}

@Riverpod(keepAlive: true)
Future<List<BeforeLogout>> beforeLogouts(Ref ref) async {
  return [];
}

@Riverpod(keepAlive: true)
Future<List<AfterLogout>> afterLogouts(Ref ref) async {
  return [];
}
