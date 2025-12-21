import 'package:core/di.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../interfaces/auth_session_storage.dart';
import 'auth_session_storage_impl.dart';

part 'local_storage_providers.g.dart';

@Riverpod(keepAlive: true)
Future<FlutterSecureStorage> flutterSecureStorage(Ref ref) async {
  return const FlutterSecureStorage();
}

@Riverpod(keepAlive: true)
Future<AuthSessionStorage> authSessionStorage(Ref ref) async {
  final storage = await ref.watch(flutterSecureStorageProvider.future);
  return AuthSessionStorageImpl(storage);
}
