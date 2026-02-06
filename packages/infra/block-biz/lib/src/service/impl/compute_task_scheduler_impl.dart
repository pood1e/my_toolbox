import 'dart:async';

import 'package:app_core/logger.dart';

import '../../data/daos/compute_property_dao.dart';
import '../../domain/property.dart';
import '../compute_task_scheduler.dart';

// File: impl/compute_task_scheduler_impl.dart

class ComputeTaskSchedulerImpl implements ComputeTaskScheduler, PropertyWatchCounter {
  final ComputePropertyDao _dao;
  final ComputeTaskWorker _worker;

  // UI 关注度状态
  final Map<PropertyKey, int> _uiCntMap = {};
  int _uiVersion = 0; // 版本号，用于 Worker 快速检测变化

  // 调度状态
  bool _isRunning = false;
  bool _hasDbDirty = false;
  StreamSubscription? _subscription;

  ComputeTaskSchedulerImpl({
    required ComputePropertyDao dao,
    required ComputeTaskWorker worker,
  }) : _dao = dao, _worker = worker;

  @override
  void start() {
    if (_subscription != null) return;
    // 监听 DB 脏标记
    _subscription = _dao.watchHasDirty().listen((hasDirty) {
      _hasDbDirty = hasDirty;
      logger.d('hasDirty changed: $hasDirty');
      // 只有当前未运行时才触发调度，防止递归调用
      if (_hasDbDirty && !_isRunning) {
        _schedule();
      }
    });
    logger.i('compute scheduler started');
  }

  @override
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// 核心调度循环：全速运行，无 delay
  void _schedule() async {
    if (_isRunning) return;
    _isRunning = true;

    try {
      // 只要 DB 还有脏数据，就一直循环
      while (_hasDbDirty) {
        // 调用 Worker，传入当前的 UI 状态源 (this)
        final result = await _worker.work(this);

        switch (result) {
          case WorkerResult.idle:
          // 没活干了，标记 DB 干净，退出循环
            _hasDbDirty = false;
            break;
          case WorkerResult.completed:
          // 这一批做完了，循环继续，再次检查 _hasDbDirty 确认是否有新产生的脏数据
            break;
          case WorkerResult.retry:
          // 遇到结构错误，立即重试（循环继续，Worker 会重新查库）
            break;
        }
      }
    } finally {
      _isRunning = false;
    }
  }

  // --- PropertyWatchCounter 实现 ---

  @override
  void subscribe(PropertyKey key) {
    _uiCntMap.update(key, (v) => v + 1, ifAbsent: () => 1);
    _uiVersion++; // 原子递增版本号
    // 注意：这里不需要手动打断 Worker，Worker 内部会轮询 version
  }

  @override
  void unsubscribe(PropertyKey key) {
    _uiCntMap.update(key, (v) => v > 0 ? v - 1 : 0, ifAbsent: () => 0);
    _uiVersion++;
  }

  // 这里的 snapshot 必须返回副本，防止 Worker 遍历时被 subscribe 修改
  @override
  Map<PropertyKey, int> get snapshot => Map.from(_uiCntMap);

  @override
  int get version => _uiVersion;
}