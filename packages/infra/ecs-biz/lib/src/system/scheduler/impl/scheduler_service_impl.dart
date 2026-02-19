import 'dart:async';

import 'package:app_core/logger.dart';

import '../data/scheduler_dao.dart';
import '../scheduler_service.dart';
import 'compute_scheduler.dart';

class SchedulerServiceImpl implements SchedulerService {
  StreamSubscription? _subscription;
  final SchedulerDao _dao;
  final ComputeScheduler _scheduler;

  SchedulerServiceImpl({
    required SchedulerDao dao,
    required ComputeScheduler scheduler,
  }) : _dao = dao,
       _scheduler = scheduler;

  @override
  void start() {
    if (_subscription != null) return;
    // 监听 DB 脏标记
    _subscription = _dao.watchHasDirty().listen((hasDirty) {
      if (hasDirty) {
        _scheduler.notifyDirty();
      }
    });
    logger.i('compute scheduler started');
  }

  @override
  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }
}
