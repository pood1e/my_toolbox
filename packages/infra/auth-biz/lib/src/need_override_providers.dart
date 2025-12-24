/// 需要框架覆盖实现
library;

import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import 'service/auth_aop.dart';

part 'need_override_providers.g.dart';

@Riverpod(keepAlive: true)
Future<List<BeforeLogin>> beforeLogins(Ref ref) async {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<List<AfterLogin>> afterLogins(Ref ref) async {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<List<BeforeLogout>> beforeLogouts(Ref ref) async {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<List<AfterLogout>> afterLogouts(Ref ref) async {
  throw NotOverrideError();
}
