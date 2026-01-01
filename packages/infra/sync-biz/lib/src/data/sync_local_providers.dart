import 'package:app_core/di.dart';
import 'package:data_api/data_api.dart';

import 'local/sync_settings_storage_impl.dart';
import 'sync_settings_storage.dart';

part 'sync_local_providers.g.dart';

@riverpod
Future<SyncSettingsStorage> syncSettingsStorage(Ref ref) async {
  final kv = await ref.watch(userKvStoreProvider('sync').future);
  return SyncSettingsStorageImpl(store: kv);
}
