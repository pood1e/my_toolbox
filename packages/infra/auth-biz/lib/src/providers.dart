import 'package:core/di.dart';

import 'service/auth_aop.dart';

part 'providers.g.dart';

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
