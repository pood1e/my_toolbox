import '../meta/property_meta_service.dart';

mixin PropertyConfigMeta on PropertyMeta {
  dynamic fromDb(Map<String, dynamic> cfg);

  Map<String, dynamic> toDb(dynamic cfg);

  Map<String, bool> buildUpdateMap(dynamic cfg, dynamic snapshot);
}

abstract class ConfigService {
  Future<void> create(PropertyId propertyId, dynamic config);

  Future<void> update(PropertyId propertyId, dynamic snapshot, dynamic config);

  Future<void> delete(PropertyId propertyId);

  // todo: save relation & analyze affect
}
