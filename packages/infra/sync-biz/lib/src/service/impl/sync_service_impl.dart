import 'package:app_core/logger.dart';
import 'package:sync_api/sync_api.dart';

import '../../data/sync_cursor_storage.dart';
import '../../domain/sync_cursor.dart';
import '../../domain/sync_exceptions.dart';
import '../sync_all_service.dart';
import '../sync_service.dart';

typedef CursorLoader = Future<int?> Function(String);
typedef CursorUpdater = Future<void> Function(String, int);
typedef SyncChecker = Future<bool> Function();

class SyncServiceImpl implements SyncService, SyncAllService {
  final Map<String, SyncDelegate> _delegateMap;
  final SyncCursorStorage _cursorStorage;
  final Map<String, SyncCursor> _cursorMap = {};
  final Map<String, bool> _syncingMap = {};

  SyncServiceImpl({
    required Map<String, SyncDelegate> delegateMap,
    required SyncCursorStorage cursorStorage,
  }) : _delegateMap = delegateMap,
       _cursorStorage = cursorStorage;

  Future<int?> _loadCursor(String resourceId) async {
    final cursor = _cursorMap[resourceId];
    if (cursor != null) {
      return cursor.cursor;
    }
    final cursorFromStorage = await _cursorStorage.load(resourceId);
    _cursorMap[resourceId] = cursorFromStorage;
    return cursorFromStorage.cursor;
  }

  Future<void> _saveCursor(String resourceId, int cursor) async {
    final syncCursor = SyncCursor(cursor: cursor, lastSyncedAt: cursor);
    _cursorMap[resourceId] = syncCursor;
    await _cursorStorage.save(resourceId, syncCursor);
  }

  @override
  Future<void> sync(String resourceId) async {
    final delegate = _delegateMap[resourceId];
    if (delegate == null) {
      logger.e('sync delegate not found: $resourceId');
      throw SyncDelegateNotFoundException();
    }

    if (_syncingMap[resourceId] ?? false) {
      logger.w('sync:$resourceId skipped: concurrent');
      throw SyncConcurrentException();
    }

    try {
      _syncingMap[resourceId] = true;
      await syncFlow(resourceId, delegate);
    } catch (e, stack) {
      logger.e('sync:$resourceId failed: $e', error: e, stackTrace: stack);
      throw SyncFailedException(message: e.toString());
    } finally {
      _syncingMap[resourceId] = false;
    }
  }

  Future<void> syncFlow(String resourceId, SyncDelegate delegate) async {
    final cursor = await _loadCursor(resourceId);
    await delegate.sync(
      cursor,
      (newCursor) => _saveCursor(resourceId, newCursor),
    );
    logger.i('sync:$resourceId completed.');
  }

  @override
  Future<void> syncAll() async {
    await Future.wait(_delegateMap.keys.map(sync));
    logger.i('syncAll completed.');
  }

  @override
  bool get anySyncing => _syncingMap.values.any((syncing) => syncing);
}
