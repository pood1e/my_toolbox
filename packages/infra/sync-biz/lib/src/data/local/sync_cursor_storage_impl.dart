import 'package:data_biz/data_biz.dart';

import '../../domain/sync_cursor.dart';
import '../sync_cursor_storage.dart';

class SyncCursorStorageImpl implements SyncCursorStorage {
  final KVStore _store;

  SyncCursorStorageImpl({required KVStore store}) : _store = store;

  @override
  Future<SyncCursor> load(String resourceId) async {
    final cursor = await _store.getInt('${resourceId}_cursor');
    final last = await _store.getInt('${resourceId}_last');
    return SyncCursor(cursor: cursor, lastSyncedAt: last);
  }

  @override
  Future<void> save(String resourceId, SyncCursor cursor) async {
    await _store.saveInt('${resourceId}_cursor', cursor.cursor!);
    await _store.saveInt('${resourceId}_last', cursor.lastSyncedAt!);
  }
}
