import '../../data/daos/property_dao.dart';
import '../../data/mappers.dart';
import '../../domain/property.dart';
import '../property_repository.dart';

class PropertyRepositoryImpl implements PropertyRepository {
  final PropertyDao _dao;

  PropertyRepositoryImpl({required PropertyDao dao}) : _dao = dao;

  @override
  Stream<Property?> watchSingle(PropertyStorageKey key) {
    return _dao
        .watchProperty(key)
        .map((property) => property.toDomain(key.type));
  }

  @override
  Stream<List<Property>> watchProperties(List<PropertyStorageKey> keys) {
    final typeMap = {
      for (final key in keys)
        PropertyKey(nodeId: key.nodeId, defId: key.defId): key.type,
    };
    return _dao
        .watchProperties(keys.toSet())
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
}
