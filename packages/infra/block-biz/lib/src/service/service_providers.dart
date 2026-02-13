import 'package:app_core/di.dart';

import '../registry/component_registry.dart';
import '../registry/property_descriptor_registry.dart';
import '../repository/property_compute_repository.dart';
import 'compute_task_scheduler.dart';
import 'impl/compute_task_impl.dart';
import 'impl/compute_task_scheduler_impl.dart';
import 'impl/compute_task_worker_impl.dart';

part 'service_providers.g.dart';

@riverpod
Future<ComputeTaskFactory> computeTaskFactory(Ref ref) async {
  final repo = await ref.watch(propertyComputeRepositoryProvider.future);
  final descriptorMap = ref.read(propertyDescriptorRegistryProvider);
  return ComputeTaskFactoryImpl(
    descriptorMap: descriptorMap,
    repo: repo,
    aggregatorRegistry: ref.read(aggregatorRegistryProvider),
    processorRegistry: ref.read(processorRegistryProvider),
    transformerRegistry: ref.read(transformerRegistryProvider),
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
