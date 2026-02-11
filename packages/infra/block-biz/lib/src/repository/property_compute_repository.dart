import 'package:app_core/di.dart';

import '../data/daos/complex_compute_dao.dart';
import '../data/daos/property_atom_config_dao.dart';
import '../data/daos/property_dao.dart';
import '../domain/data_type.dart';
import '../domain/property.dart';
import '../domain/property_config.dart';
import '../domain/stored_value.dart';
import '../supports/config_spec_registry.dart';
import 'impl/property_compute_repository_impl.dart';

part 'property_compute_repository.g.dart';

abstract class PropertyComputeRepository {
  Future<List<PropertyKey>> getDirties();

  Future<List<DependencyEdge>> getDirtyDependencyEdges(
    List<PropertyKey> dirties,
  );

  Stream<bool> watchHasDirty();

  Future<void> saveProperties(List<Property> properties);

  Future<Map<PropertyKey, Property>> getProperties(
    Map<PropertyKey, DataTypeDefinition> keyMap,
  );

  Future<void> saveProperty(Property property);

  Future<void> deleteProperty(PropertyKey key);

  Future<PropertyConfig?> getConfig(PropertyKey key);

  Future<void> markErrorRecursive({
    required Set<PropertyKey> rootKeys,
    required ValueError rootError,
  });

  Future<void> markDirtyRecursive({
    required Set<PropertyKey> rootKeys,
    bool includeSelf = true,
  });

  Future<T> transcation<T>(Future<T> Function() action);
}

class DependencyEdge {
  final PropertyKey source; // 依赖者 (Effect / result) -> 需要等待
  final PropertyKey target; // 被依赖者 (Cause / dependency) -> 需要先算

  DependencyEdge({required this.source, required this.target});
}

@riverpod
Future<PropertyComputeRepository> propertyComputeRepository(Ref ref) async {
  final propertyDao = await ref.watch(propertyDaoProvider.future);
  final configDao = await ref.watch(propertyAtomConfigDaoProvider.future);
  final computeDao = await ref.watch(complexComputeDaoProvider.future);
  final descriptorMap = ref.read(configSpecDescriptorRegistryProvider);
  return PropertyComputeRepositoryImpl(
    configDao: configDao,
    propertyDao: propertyDao,
    computeDao: computeDao,
    descriptorMap: descriptorMap,
  );
}
