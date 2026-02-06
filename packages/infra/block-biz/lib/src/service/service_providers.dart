import 'package:app_core/di.dart';

import '../data/daos/compute_property_dao.dart';
import '../data/daos/property_dao.dart';
import '../supports/property_def_registry.dart';
import 'compute_task_scheduler.dart';
import 'evalutor.dart';
import 'impl/compute_task_impl.dart';
import 'impl/compute_task_scheduler_impl.dart';
import 'impl/compute_task_worker_impl.dart';
import 'impl/evalutor_context_impl.dart';

part 'service_providers.g.dart';

@riverpod
Future<EvalutorContext> evalutorContext(Ref ref) async {
  final dao = await ref.watch(propertyDaoProvider.future);
  final descriptorMap = ref.read(propertyDefRegistryProvider);
  return EvalutorContextImpl(dao: dao, descriptorMap: descriptorMap);
}

@riverpod
Future<ComputeTaskFactory> computeTaskFactory(Ref ref) async {
  final dao = await ref.watch(computePropertyDaoProvider.future);
  final descriptorMap = ref.read(propertyDefRegistryProvider);
  final evalutorContext = await ref.read(evalutorContextProvider.future);
  return ComputeTaskFactoryImpl(
    descriptorMap: descriptorMap,
    dao: dao,
    evalutorContext: evalutorContext,
  );
}

@riverpod
Future<ComputeTaskWorker> computeTaskWorker(Ref ref) async {
  final dao = await ref.watch(computePropertyDaoProvider.future);
  final factory = await ref.watch(computeTaskFactoryProvider.future);
  return ComputeTaskWorkerImpl(dao: dao, contextFactory: factory);
}

@riverpod
Future<ComputeTaskScheduler> computeTaskScheduler(Ref ref) async {
  final dao = await ref.watch(computePropertyDaoProvider.future);
  final worker = await ref.watch(computeTaskWorkerProvider.future);
  return ComputeTaskSchedulerImpl(dao: dao, worker: worker);
}

@riverpod
Future<PropertyWatchCounter> propertyWatchCounter(Ref ref) async {
  final scheduler = await ref.watch(computeTaskSchedulerProvider.future);
  return scheduler as PropertyWatchCounter;
}
