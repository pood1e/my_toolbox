import 'package:app_core/core.dart';
import 'package:app_core/di.dart';

import 'system/scheduler/scheduler_service.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
StartupAction startComputeTaskScheduler(Ref ref) => () async {
  final scheduler = await ref.watch(schedulerServiceProvider.future);
  scheduler.start();
};
