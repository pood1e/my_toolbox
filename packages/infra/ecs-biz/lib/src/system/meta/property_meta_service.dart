import 'package:app_core/di.dart';
import 'package:app_core/object.dart';

import 'impl/property_meta_service_impl.dart';
import 'registry/name_meta.dart';

part 'property_meta_service.freezed.dart';
part 'property_meta_service.g.dart';

abstract class PropertyMeta {
  String get metaId;
}

@freezed
abstract class PropertyId with _$PropertyId {
  const factory PropertyId({required String nodeId, required String metaId}) =
      _PropertyId;
}

abstract class PropertyMetaService {
  PropertyMeta? getById(String metaId);
}

@Riverpod(keepAlive: true)
PropertyMetaService propertyMetaService(Ref ref) =>
    PropertyMetaServiceImpl(metas: [NameMeta()]);
