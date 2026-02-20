import 'package:app_core/core.dart';
import 'package:app_core/di.dart';
import 'package:app_core/route.dart';
import 'package:auth_biz/auth_biz.dart';
import 'package:block_biz/block_biz.dart';
import 'package:ecs_biz/ecs_biz.dart';
import 'package:framework_api/framework_api.dart';
import 'package:shell_biz/shell_biz.dart';
import 'package:sync_biz/sync_biz.dart';

part 'framework_registry.g.dart';

class FrameworkRegistry {
  FrameworkRegistry();

  List<RouteBase> routes(Ref ref) => [
    ...ref.read(shellRoutesProvider),
    ...ref.read(ecsRoutesProvider),
  ];

  List<StartupAction> startups(Ref ref) => [
    ref.read(checkTokenActionProvider),
    ref.read(checkRealtimeSyncProvider),
    ref.read(startComputeTaskSchedulerProvider),
  ];

  Future<List<SyncDelegate>> syncDelegates(Ref ref) async => [
    await ref.watch(appUsageSyncDelegateProvider.future),
  ];
}

@riverpod
FrameworkRegistry frameworkRegistry(Ref ref) {
  return FrameworkRegistry();
}
