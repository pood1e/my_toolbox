import 'dart:async';

import 'package:app_core/logger.dart';
import 'package:sync_api/sync_api.dart';

import '../../domain/sync_exceptions.dart';
import '../sync_all_service.dart';

class SyncServiceImpl implements SyncService, SyncAllService {
  final Map<String, SyncDelegate> _delegateMap;
  final Map<String, bool> _syncingMap = {};
  final Map<String, Completer<void>> _pendingCompleters = {};

  SyncServiceImpl({required Map<String, SyncDelegate> delegateMap})
    : _delegateMap = delegateMap;

  @override
  Future<void> sync(String resourceId) async {
    final delegate = _delegateMap[resourceId];
    if (delegate == null) {
      throw SyncDelegateNotFoundException();
    }

    // 1. 如果正在同步，则加入排队 (或者复用已有的排队)
    if (_isSyncing(resourceId)) {
      logger.i('🔄 [Sync:$resourceId] Busy. Joining the pending queue.');
      return _enqueueAndWait(resourceId);
    }

    // 2. 如果空闲，开启排水循环
    // 注意：这里我们 await _drainLoop，意味着当前调用者会等待同步完成
    await _drainLoop(resourceId, delegate);
  }

  /// 加入排队并等待
  Future<void> _enqueueAndWait(String resourceId) {
    // 获取当前排队的 Completer，如果没有则新建一个
    var completer = _pendingCompleters[resourceId];
    if (completer == null) {
      completer = Completer<void>();
      _pendingCompleters[resourceId] = completer;
    }
    // 返回 Future，调用者在这里 await，直到下一轮 sync 完成
    return completer.future;
  }

  /// 任务排水循环
  Future<void> _drainLoop(String resourceId, SyncDelegate delegate) async {
    _setSyncing(resourceId, true);

    try {
      // 至少执行一次 (本次请求)
      // 如果在执行过程中有新请求进来，_pendingCompleters 会被赋值，循环继续
      do {
        // --- 阶段 A: 取出当前的排队通知器 (快照) ---
        // 我们要在执行 sync 之前(或之后)取出它，以便在执行完后 complete 它
        final currentPending = _pendingCompleters[resourceId];
        // 从 Map 中移除，这样 sync 执行期间进来的新请求会创建一个新的 Completer
        if (currentPending != null) {
          _pendingCompleters.remove(resourceId);
        }

        // --- 阶段 B: 执行同步 ---
        logger.i('🚀 [Sync:$resourceId] Executing...');
        try {
          await delegate.sync();
          logger.i('✅ [Sync:$resourceId] Completed.');

          // 通知在排队等待的调用者：成功
          currentPending?.complete();
        } catch (e, s) {
          logger.e('❌ [Sync:$resourceId] Failed: $e');

          // 通知在排队等待的调用者：失败
          // 这样调用 syncNow() 的 UI 就能捕获到异常
          currentPending?.completeError(e, s);
        }

        // --- 阶段 C: 检查是否还有新的排队 ---
        // 循环条件：_pendingCompleters[resourceId] != null
        // 如果在刚才 await delegate.sync() 期间又有新调用，_enqueueAndWait 会放入新的 Completer
      } while (_pendingCompleters.containsKey(resourceId));
    } finally {
      _setSyncing(resourceId, false);
    }
  }

  @override
  Future<void> syncAll() async {
    await Future.wait(_delegateMap.keys.map((id) => sync(id)));
  }

  @override
  bool get anySyncing => _syncingMap.values.any((v) => v);

  bool _isSyncing(String id) => _syncingMap[id] ?? false;

  void _setSyncing(String id, bool value) {
    if (value) {
      _syncingMap[id] = true;
    } else {
      _syncingMap.remove(id);
    }
  }
}
