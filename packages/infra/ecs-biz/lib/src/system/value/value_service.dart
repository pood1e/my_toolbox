import 'package:app_core/object.dart';

import '../meta/property_meta_service.dart';

part 'value_service.freezed.dart';

@freezed
abstract class PropertyVal with _$PropertyVal {
  const factory PropertyVal({
    dynamic value,

    required ValueStatus status,

    String? extra,
  }) = _PropertyVal;
}

enum ValueStatus { normal, dirty, error }

enum StorageType { bool, int, real, text, json, str }

abstract class DataType<T> {
  String get id;

  T? fromDb(dynamic value);

  dynamic toDb(T value);
}

mixin PropertyValueMeta on PropertyMeta {
  String? get dataTypeId => null;

  StorageType get storageType;
}

abstract class ValueService {
  Future<PropertyVal?> getValue(PropertyId propertyId);

  Future<void> update(PropertyId propertyId, PropertyVal val);

  Future<void> delete(PropertyId propertyId);

  Future<void> markAsDirty(List<PropertyId> propertyIds);
}
