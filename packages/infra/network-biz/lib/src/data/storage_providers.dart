import 'package:app_core/di.dart';
import 'package:data_api/data_api.dart';

import 'impl/install_id_storage_impl.dart';
import 'impl/server_time_storage_impl.dart';
import 'install_id_storage.dart';
import 'server_time_storage.dart';

part 'storage_providers.g.dart';

@riverpod
Future<ServerTimeStorage> serverTimeStorage(Ref ref) async {
  final kv = await ref.watch(userKvStoreProvider('time').future);
  return ServerTimeStorageImpl(store: kv);
}

@riverpod
Future<InstallIdStorage> deviceIdStorage(Ref ref) async {
  final kv = await ref.watch(globalKvStoreProvider('install_id').future);
  return InstallIdStorageImpl(store: kv);
}
