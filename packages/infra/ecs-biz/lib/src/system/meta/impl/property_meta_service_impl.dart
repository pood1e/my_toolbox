import '../property_meta_service.dart';

class PropertyMetaServiceImpl implements PropertyMetaService {
  final Map<String, PropertyMeta> _map;

  PropertyMetaServiceImpl({required List<PropertyMeta> metas})
    : _map = {for (final meta in metas) meta.metaId: meta};

  @override
  PropertyMeta? getById(String metaId) => _map[metaId];
}
