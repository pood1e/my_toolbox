import 'package:app_core/object.dart';

import 'stored_value.dart';

part 'property.freezed.dart';

@freezed
abstract class PropertyKey with _$PropertyKey {
  const factory PropertyKey({required String nodeId, required String defId}) =
      _PropertyKey;
}

/// 值
@freezed
abstract class Property with _$Property {
  const factory Property({
    required PropertyKey key,
    required StoredValue value,
    // raw value
  }) = _Property;
}
