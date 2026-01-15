import 'dart:async';

import 'package:sync_api/sync_api.dart';

class AutoSyncServiceImpl implements AutoSyncService {
  final SyncService _syncService;

  // 仅管理防抖计时器
  final Map<String, Timer> _timers = {};

  AutoSyncServiceImpl(this._syncService);

  /// [防抖触发] 数据库变更时调用
  @override
  void markSync(
    String resourceId, {
    Duration debounce = const Duration(seconds: 5),
  }) {
    // 1. 无论当前什么状态，先取消之前的倒计时
    _timers[resourceId]?.cancel();

    // 2. 开启新的倒计时
    _timers[resourceId] = Timer(debounce, () {
      _timers.remove(resourceId);
      // 3. 时间到 -> 发起同步 (底层 SyncService 会处理是立即跑还是排队)
      _syncService.sync(resourceId);
    });
  }

  /// [立即触发] UI 强制调用
  @override
  Future<void> flushPending(String resourceId) async {
    if (_timers.containsKey(resourceId)) {
      _timers[resourceId]?.cancel();
      _timers.remove(resourceId);
      await _syncService.sync(resourceId);
    }
  }

  void dispose() {
    for (var t in _timers.values) {
      t.cancel();
    }
    _timers.clear();
  }
}
