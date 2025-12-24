import 'package:app_core/logger.dart';
import 'package:sync_api/sync_api.dart';

import '../../domain/sync_exceptions.dart';
import '../sync_all_service.dart';
import '../sync_service.dart';

typedef CursorLoader = Future<int?> Function(String);
typedef CursorUpdater = Future<void> Function(String, int);
typedef SyncChecker = Future<bool> Function();
typedef SyncingSetter = void Function(String, bool);
typedef SyncingGetter = bool Function(String);

class SyncServiceImpl implements SyncService, SyncAllService {
  final Map<String, SyncDelegate<dynamic>> _delegateMap;
  final SyncChecker _syncChecker;
  final CursorLoader _cursorLoader;
  final CursorUpdater _cursorUpdater;
  final SyncingGetter _syncingGetter;
  final SyncingSetter _syncingSetter;

  SyncServiceImpl({
    required Map<String, SyncDelegate<dynamic>> delegateMap,
    required SyncChecker syncChecker,
    required CursorLoader cursorLoader,
    required CursorUpdater cursorUpdater,
    required SyncingGetter syncingGetter,
    required SyncingSetter syncingSetter,
  }) : _delegateMap = delegateMap,
       _syncChecker = syncChecker,
       _cursorLoader = cursorLoader,
       _cursorUpdater = cursorUpdater,
       _syncingGetter = syncingGetter,
       _syncingSetter = syncingSetter;

  @override
  Future<void> sync(String resourceId) async {
    if (!(await _syncChecker())) {
      logger.w('cannot sync now');
      throw SyncDisallowException();
    }

    final delegate = _delegateMap[resourceId];
    if (delegate == null) {
      logger.e('sync delegate not found: $resourceId');
      throw SyncDelegateNotFoundException();
    }

    if (_syncingGetter(resourceId)) {
      logger.w('sync:$resourceId skipped: concurrent');
      throw SyncConcurrentException();
    }

    try {
      _syncingSetter(resourceId, true);
      await syncFlow(resourceId, delegate);
    } catch (e, stack) {
      logger.e('sync:$resourceId failed: $e', error: e, stackTrace: stack);
      throw SyncFailedException(message: e.toString());
    } finally {
      _syncingSetter(resourceId, false);
    }
  }

  Future<void> syncFlow(
    String resourceId,
    SyncDelegate<dynamic> delegate,
  ) async {
    final cursor = await _cursorLoader(resourceId);
    final changes = await delegate.load(cursor);

    if (changes != null && !delegate.isEmpty(changes)) {
      await delegate.push(changes);
      logger.i('sync:$resourceId push changes successfully.');
    } else {
      logger.i('sync:$resourceId no changes to push.');
    }

    logger.i('sync:$resourceId pulling remote changes...');
    final result = await delegate.pull(cursor);
    if (!delegate.isEmpty(result.payload)) {
      await delegate.merge(result.payload);
      logger.i('sync:$resourceId merge changes successfully.');
    } else {
      logger.i('sync:$resourceId no changes to merge.');
    }

    await _cursorUpdater(resourceId, result.cursor);
    logger.i('sync:$resourceId completed.');
  }

  @override
  Future<void> syncAll() async {
    await Future.wait(_delegateMap.keys.map(sync));
    logger.i('syncAll completed.');
  }
}
