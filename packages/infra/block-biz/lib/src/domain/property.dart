import 'package:app_core/object.dart';

import 'property_descriptor.dart';

part 'property.freezed.dart';

enum ValueStatus { normal, dirty, error }

enum ComputeError {
  // 自身配置错误
  config,
  // 引用配置错误
  ref,
  // 环状依赖
  cycle,
}

@freezed
abstract class PropertyKey with _$PropertyKey {
  const factory PropertyKey({required String nodeId, required String defId}) =
      _PropertyKey;
}

@freezed
abstract class PropertyStorageKey with _$PropertyStorageKey {
  const factory PropertyStorageKey({
    required String nodeId,
    required String defId,
    required StorageType type,
  }) = _PropertyStorageKey;
}

@freezed
sealed class PropertyValue with _$PropertyValue {
  const factory PropertyValue.success({dynamic value}) = SuccessPropertyValue;

  const factory PropertyValue.dirty({dynamic value}) = DirtyPropertyValue;

  const factory PropertyValue.error({required ComputeError error}) = ErrorPropertyValue;
}


/// 值
@freezed
abstract class Property with _$Property {
  const factory Property({
    required PropertyStorageKey key,
    required PropertyValue value
    // raw value
  }) = _Property;
}

