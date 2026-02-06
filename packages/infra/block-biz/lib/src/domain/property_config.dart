import 'package:app_core/object.dart';

import 'property.dart';

part 'property_config.freezed.dart';

@freezed
sealed class PropertyConfigRecord with _$PropertyConfigRecord {
  const factory PropertyConfigRecord({
    String? configKey,
    String? mapKey,
    String? targetNodeId,
    String? targetDefId,
    String? config,
    @Default(true) bool affectValue,
  }) = _PropertyConfigRecord;
}

@freezed
abstract class PropertyConfig with _$PropertyConfig {
  const factory PropertyConfig({
    required PropertyKey key,
    required List<PropertyConfigRecord> records,
  }) = _PropertyConfig;
}
