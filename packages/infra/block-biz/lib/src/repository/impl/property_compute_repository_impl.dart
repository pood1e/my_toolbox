import 'package:drift/drift.dart';

import '../../data/daos/complex_compute_dao.dart';
import '../../data/daos/property_atom_config_dao.dart';
import '../../data/daos/property_dao.dart';
import '../../domain/property.dart';
import '../../domain/property_config.dart';
import '../../domain/stored_value.dart';
import '../../mappers/property_config_mapper.dart';
import '../../mappers/property_mapper.dart';
import '../property_compute_repository.dart';

class PropertyComputeRepositoryImpl implements PropertyComputeRepository {
  final PropertyAtomConfigDao _configDao;
  final PropertyDao _propertyDao;
  final ComplexComputeDao _computeDao;

  PropertyComputeRepositoryImpl({
    required PropertyAtomConfigDao configDao,
    required PropertyDao propertyDao,
    required ComplexComputeDao computeDao,
  }) : _configDao = configDao,
       _propertyDao = propertyDao,
       _computeDao = computeDao;

  @override
  Future<void> deleteProperty(PropertyKey key) =>
      _propertyDao.deleteProperty(key);

  @override
  Future<PropertyConfig?> getConfig(PropertyKey key) async {
    final entities = await _configDao.getByKey(key);
    return entities.toDomain(key);
  }

  @override
  Future<List<DependencyEdge>> getDirtyDependencyEdges(
    List<PropertyKey> dirties,
  ) async {
    final rows = await _computeDao.getDirtyDependencyEdges(dirties);
    return rows.map((row) => row.toEdge()).toList();
  }

  @override
  Future<void> markErrorRecursive({
    required Set<PropertyKey> rootKeys,
    required ValueError rootError,
  }) =>
      _computeDao.markErrorRecursive(rootKeys: rootKeys, rootError: rootError);

  @override
  Future<void> saveProperties(List<Property> properties) =>
      _propertyDao.saveProperties(
        properties.map((property) => property.toCompanion()).toList(),
      );

  @override
  Future<void> saveProperty(Property property) =>
      _propertyDao.saveProperty(property.toCompanion());

  @override
  Future<T> transcation<T>(Future<T> Function() action) =>
      _computeDao.transaction(action);

  @override
  Future<List<PropertyKey>> getDirties() => _computeDao.getDirtyProperties();

  @override
  Future<void> markDirtyRecursive({
    required Set<PropertyKey> rootKeys,
    bool includeSelf = true,
  }) => _computeDao.markDirtyRecursive(
    rootKeys: rootKeys,
    includeSelf: includeSelf,
  );

  @override
  Stream<bool> watchHasDirty() => _computeDao.watchHasDirty();
}

extension RowToDependencyEdge on QueryRow {
  DependencyEdge toEdge() => DependencyEdge(
    source: PropertyKey(nodeId: read('node_id'), defId: read('def_id')),
    target: PropertyKey(
      nodeId: read('target_node_id'),
      defId: read('target_def_id'),
    ),
  );
}
