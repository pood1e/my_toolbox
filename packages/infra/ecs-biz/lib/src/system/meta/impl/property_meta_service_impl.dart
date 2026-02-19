import '../property_meta_service.dart';

class PropertyMetaServiceImpl implements PropertyMetaService {
  final Map<String, PropertyMeta> _map;

  PropertyMetaServiceImpl({required Map<String, PropertyMeta> map})
    : _map = map;

  @override
  PropertyMeta? getById(String metaId) => _map[metaId];
}
