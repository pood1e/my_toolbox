import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import '../compute/compute_service.dart';
import '../config/config_service.dart';
import '../meta/property_meta_service.dart';
import '../relation/relation_service.dart';
import '../value/value_service.dart';
import 'data/scheduler_dao.dart';
import 'impl/compute_priority_service_impl.dart';
import 'impl/compute_scheduler.dart';
import 'impl/compute_scheduler_impl.dart';
import 'impl/compute_worker.dart';
import 'impl/compute_worker_impl.dart';
import 'impl/scheduler_service_impl.dart';

part 'scheduler_service.freezed.dart';
part 'scheduler_service.g.dart';

abstract class SchedulerService {
  void start();

  void stop();
}

@freezed
abstract class HighPriorityState with _$HighPriorityState {
  const factory HighPriorityState({
    required int version,
    required Set<PropertyId> propertyIds,
  }) = _HighPriorityState;
}

abstract class ComputePriorityService {
  void markHighPriority(PropertyId propertyId);

  void removeHighPriority(PropertyId propertyId);

  HighPriorityState getHighPriorityState();

  int getHighPriorityVersion();
}

@riverpod
Future<ComputePriorityService> computePriorityService(Ref ref) async =>
    ComputePriorityServiceImpl();

@riverpod
Future<ComputeWorker> computeWorker(Ref ref) async {
  final dao = await ref.watch(schedulerDaoProvider.future);
  final metaService = ref.watch(propertyMetaServiceProvider);
  final configService = await ref.watch(configServiceProvider.future);
  final valueService = await ref.watch(valueServiceProvider.future);
  final relationService = await ref.watch(relationServiceProvider.future);
  final computeService = await ref.watch(computeServiceProvider.future);

  return ComputeWorkerImpl(
    metaService: metaService,
    computeService: computeService,
    configService: configService,
    valueService: valueService,
    relationService: relationService,
    dao: dao,
  );
}

@riverpod
Future<ComputeScheduler> computeScheduler(Ref ref) async {
  final valueService = await ref.watch(valueServiceProvider.future);
  final computePriorityService = await ref.watch(
    computePriorityServiceProvider.future,
  );
  final computeWorker = await ref.watch(computeWorkerProvider.future);
  final dao = await ref.watch(schedulerDaoProvider.future);
  return ComputeSchedulerImpl(
    valueService: valueService,
    priorityService: computePriorityService,
    worker: computeWorker,
    dao: dao,
  );
}

@riverpod
Future<SchedulerService> schedulerService(Ref ref) async {
  final dao = await ref.watch(schedulerDaoProvider.future);
  final scheduler = await ref.watch(computeSchedulerProvider.future);
  return SchedulerServiceImpl(dao: dao, scheduler: scheduler);
}
