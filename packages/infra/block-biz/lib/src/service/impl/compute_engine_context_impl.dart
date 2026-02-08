import '../../data/daos/property_dao.dart';
import '../../domain/property.dart';
import '../../domain/property_descriptor.dart';
import '../../domain/stored_value.dart';
import '../../domain/type_descriptor.dart';
import '../../mappers/property_mapper.dart';

class ComputeEngineContextImpl extends ComputeEngineContext {
  final PropertyDao _dao;
  final Map<String, PropertyDescriptor> _descriptorMap;

  ComputeEngineContextImpl({
    required PropertyDao dao,
    required Map<String, PropertyDescriptor> descriptorMap,
  }) : _dao = dao,
       _descriptorMap = descriptorMap;

  @override
  Future<Map<PropertyKey, Property>> getProperties(
    Set<PropertyKey> keys,
  ) async {
    final propertyEntities = await _dao.getProperties(keys);
    final result = <PropertyKey, Property>{};
    for (final entity in propertyEntities) {
      final descriptor = _descriptorMap[entity.defId]!;
      final property = entity.toDomain(descriptor.typeDescriptor.storageType);
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
  Future<T> convertValue<T>(PropertyKey key, NormalStoredValue value) async {
    final descriptor = _descriptorMap[key.defId]!;
    return descriptor.typeDescriptor.valueConverter.decode(value.value);
  }
}
