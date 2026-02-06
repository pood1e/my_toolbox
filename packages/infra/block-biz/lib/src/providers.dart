import 'package:app_core/core.dart';
import 'package:app_core/di.dart';

import 'service/service_providers.dart';

part 'providers.g.dart';

@Riverpod(keepAlive: true)
StartupAction startComputeTaskScheduler(Ref ref) {
  return () async {
    final scheduler = await ref.watch(computeTaskSchedulerProvider.future);
    scheduler.start();
  };
}
