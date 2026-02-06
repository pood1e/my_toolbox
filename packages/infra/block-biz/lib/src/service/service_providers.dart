import 'package:app_core/di.dart';

import '../data/daos/property_dao.dart';
import '../repository/property_compute_repository.dart';
import '../supports/property_def_registry.dart';
import 'compute_engine_context.dart';
import 'compute_task_scheduler.dart';
import 'impl/compute_engine_context_impl.dart';
import 'impl/compute_task_impl.dart';
import 'impl/compute_task_scheduler_impl.dart';
import 'impl/compute_task_worker_impl.dart';

part 'service_providers.g.dart';

@riverpod
Future<ComputeEngineContext> computeEngineContext(Ref ref) async {
  final dao = await ref.watch(propertyDaoProvider.future);
  final descriptorMap = ref.read(propertyDefRegistryProvider);
  return ComputeEngineContextImpl(dao: dao, descriptorMap: descriptorMap);
}

@riverpod
Future<ComputeTaskFactory> computeTaskFactory(Ref ref) async {
  final repo = await ref.watch(propertyComputeRepositoryProvider.future);
  final descriptorMap = ref.read(propertyDefRegistryProvider);
  final computeEngineContext = await ref.read(
    computeEngineContextProvider.future,
  );
  return ComputeTaskFactoryImpl(
    descriptorMap: descriptorMap,
    repo: repo,
    engineCtx: computeEngineContext,
  );
}

@riverpod
Future<ComputeTaskWorker> computeTaskWorker(Ref ref) async {
  final repo = await ref.watch(propertyComputeRepositoryProvider.future);
  final factory = await ref.watch(computeTaskFactoryProvider.future);
  return ComputeTaskWorkerImpl(repo: repo, contextFactory: factory);
}

@riverpod
Future<ComputeTaskScheduler> computeTaskScheduler(Ref ref) async {
  final repo = await ref.watch(propertyComputeRepositoryProvider.future);
  final worker = await ref.watch(computeTaskWorkerProvider.future);
  return ComputeTaskSchedulerImpl(repo: repo, worker: worker);
}

@riverpod
Future<PropertyWatchCounter> propertyWatchCounter(Ref ref) async {
  final scheduler = await ref.watch(computeTaskSchedulerProvider.future);
  return scheduler as PropertyWatchCounter;
}
