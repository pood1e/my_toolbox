import '../../data/daos/property_dao.dart';
import '../../data/mappers.dart';
import '../evalutor.dart';
import '../../domain/property.dart';
import '../../domain/property_descriptor.dart';

class EvalutorContextImpl extends EvalutorContext {
  final PropertyDao _dao;
  final Map<String, PropertyDescriptor> _descriptorMap;

  EvalutorContextImpl({
    required PropertyDao dao,
    required Map<String, PropertyDescriptor> descriptorMap,
  }) : _dao = dao,
       _descriptorMap = descriptorMap;

  @override
  Future<Map<PropertyKey, Property>> getProperties(
    Set<PropertyKey> keys,
  ) async {
    final propertyEntities = await _dao.getProperties(
      keys
          .map(
            (key) => PropertyStorageKey(
              nodeId: key.nodeId,
              defId: key.defId,
              type: _descriptorMap[key.defId]!.valueDescriptor.storageType,
            ),
          )
          .toSet(),
    );
    final result = <PropertyKey, Property>{};
    for (final entity in propertyEntities) {
      final descriptor = _descriptorMap[entity.defId]!;
      final property = entity.toDomain(descriptor.valueDescriptor.storageType);
      result[PropertyKey(nodeId: entity.nodeId, defId: entity.defId)] =
          property;
    }
    return result;
  }

  @override
  Future<Property?> getProperty(PropertyKey key) async {
    final mapResult = await getProperties({key});
    return mapResult[key];
  }

  @override
  Future<T> convertValue<T>(PropertyKey key, Property value) async {
    final descriptor = _descriptorMap[key.defId]!;
    return descriptor.valueDescriptor.decode(value.value);
  }
}


