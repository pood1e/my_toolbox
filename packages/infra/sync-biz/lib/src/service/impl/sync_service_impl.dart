import 'package:core/logger.dart';
import 'package:sync_api/sync_api.dart';

import '../../domain/sync_exceptions.dart';
import '../sync_all_service.dart';

class SyncServiceImpl implements SyncService, SyncAllService {
  final Map<String, SyncDelegate<dynamic>> _delegateMap;
  final Future<bool> Function() _canSync;
  final Future<int?> Function(String) _loadCursor;
  final Future<void> Function(String, int) _saveCursor;

  SyncServiceImpl({
    required Map<String, SyncDelegate<dynamic>> delegateMap,
    required Future<bool> Function() canSync,
    required Future<int?> Function(String) loadCursor,
    required Future<void> Function(String, int) saveCursor,
  }) : _delegateMap = delegateMap,
       _canSync = canSync,
       _loadCursor = loadCursor,
       _saveCursor = saveCursor;

  final Map<String, bool> _syncingMap = {};

  @override
  Future<void> sync(String resourceId) async {
    if (!(await _canSync())) {
      logger.w('cannot sync now');
      throw SyncDisallowException();
    }

    final delegate = _delegateMap[resourceId];
    if (delegate == null) {
      logger.e('sync delegate not found: $resourceId');
      throw SyncDelegateNotFoundException();
    }

    if (_syncingMap[resourceId] == true) {
      logger.w('sync:$resourceId skipped: concurrent');
      throw SyncConcurrentException();
    }
  }

  Future<void> syncFlow(
    String resourceId,
    SyncDelegate<dynamic> delegate,
  ) async {
    _syncingMap[resourceId] = true;
    try {
      final cursor = await _loadCursor(resourceId);
      final changes = await delegate.load(cursor);

      if (changes != null && !delegate.isEmpty(changes)) {
        logger.i('sync:$resourceId pushing changes...');
        await delegate.push(changes);
        logger.i('sync:$resourceId push changes successfully');
      } else {
        logger.i('sync:$resourceId no changes to push.');
      }

      logger.i('sync:$resourceId pulling remote changes...');
      final result = await delegate.pull(cursor);
      if (!delegate.isEmpty(result.payload)) {
        await delegate.merge(result.payload);
        logger.i('sync:$resourceId merge changes successfully');
      } else {
        logger.i('sync:$resourceId no changes to merge.');
      }

      await _saveCursor(resourceId, result.cursor);
      logger.i('sync:$resourceId completed');
    } catch (e, stack) {
      logger.e('sync:$resourceId failed: $e', error: e, stackTrace: stack);
      throw SyncFailedException(message: e.toString());
    } finally {
      _syncingMap[resourceId] = false;
    }
  }

  @override
  Future<void> syncAll() async {
    await Future.wait(_delegateMap.keys.map(sync));
  }
}
