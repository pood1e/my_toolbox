import '../domain/sync_cursor.dart';

abstract class SyncCursorStorage {
  Future<SyncCursor> load(String resourceId);

  Future<void> save(String resourceId, SyncCursor cursor);
}
