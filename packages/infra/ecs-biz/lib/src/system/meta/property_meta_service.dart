import 'package:app_core/object.dart';

part 'property_meta_service.freezed.dart';

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