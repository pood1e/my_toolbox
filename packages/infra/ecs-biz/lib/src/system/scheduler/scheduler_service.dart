import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';

part 'scheduler_service.freezed.dart';

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
