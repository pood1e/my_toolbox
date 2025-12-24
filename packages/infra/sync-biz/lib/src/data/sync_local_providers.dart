import 'package:app_core/di.dart';
import 'package:data_biz/data_biz.dart';

import 'local/sync_cursor_storage_impl.dart';
import 'local/sync_settings_storage_impl.dart';
import 'sync_cursor_storage.dart';
import 'sync_settings_storage.dart';

part 'sync_local_providers.g.dart';

@riverpod
Future<SyncCursorStorage> syncCursorStorage(Ref ref) async {
  final kv = await ref.watch(userKvStoreProvider('sync').future);
  return SyncCursorStorageImpl(store: kv);
}

@riverpod
Future<SyncSettingsStorage> syncSettingsStorage(Ref ref) async {
  final kv = await ref.watch(userKvStoreProvider('sync').future);
  return SyncSettingsStorageImpl(store: kv);
}
