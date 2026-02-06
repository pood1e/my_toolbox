import '../../data/daos/property_dao.dart';
import '../../domain/property.dart';
import '../../domain/stored_value.dart';
import '../../mappers/property_mapper.dart';
import '../property_repository.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyDao _dao;

  PropertyRepositoryImpl({required PropertyDao dao}) : _dao = dao;

  @override
  Stream<Property?> watchSingle(PropertyKey key, StorageType type) =>
      _dao.watchProperty(key).map((property) => property.toDomain(type));

  @override
  Stream<List<Property>> watchProperties(
    Map<PropertyKey, StorageType> typeMap,
  ) => _dao
      .watchProperties(typeMap.keys.toSet())
      .map(
        (properties) => properties
            .map(
              (property) => property.toDomain(
                typeMap[PropertyKey(
                  nodeId: property.nodeId,
                  defId: property.defId,
                )]!,
              ),
            )
            .toList(),
      );
}
