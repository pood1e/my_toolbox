import '../../meta/property_meta_service.dart';
import '../scheduler_service.dart';

class ComputePriorityServiceImpl implements ComputePriorityService {
  final Map<PropertyId, int> _map = {};
  int _version = 0;

  @override
  HighPriorityState getHighPriorityState() => HighPriorityState(
    version: _version,
    propertyIds: _map.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toSet(),
  );

  @override
  int getHighPriorityVersion() => _version;

  @override
  void markHighPriority(PropertyId propertyId) {
    _map.update(propertyId, (old) => old + 1, ifAbsent: () => 1);
    _version++;
  }

  @override
  void removeHighPriority(PropertyId propertyId) {
    _map.update(propertyId, (old) => old - 1);
    _version++;
  }
}
