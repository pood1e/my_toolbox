import 'package:app_core/di.dart';
import 'package:app_core/http.dart';
import 'package:app_core/object.dart';

import 'domain/user_identity.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
Future<Dio> authenticatedDio(Ref ref) async {
  throw NotOverrideError();
}

@Riverpod(keepAlive: true)
Future<UserIdentity?> currentUserIdentity(Ref ref) async {
  throw NotOverrideError();
}
